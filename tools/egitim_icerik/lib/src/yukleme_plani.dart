import 'dart:convert';
import 'icerik_birlestir.dart';

class YuklemeHatasi implements Exception {
  final String mesaj;
  YuklemeHatasi(this.mesaj);
  @override
  String toString() => mesaj;
}

Uri apiAdresi(String metin) {
  final uri = Uri.tryParse(metin);
  if (uri == null ||
      !{'http', 'https'}.contains(uri.scheme) ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    throw YuklemeHatasi(
      'API adresi http/https olmalı; kullanıcı bilgisi, sorgu veya fragment içermemeli.',
    );
  }
  return uri.replace(path: uri.path.endsWith('/') ? uri.path : '${uri.path}/');
}

bool yerelAdres(Uri uri) =>
    {'localhost', '127.0.0.1', '::1', '[::1]'}.contains(uri.host);

class YuklemePlani {
  final Map<String, dynamic> paket;
  final List<String> kayiplar;
  final List<String> uyarilar;
  YuklemePlani(this.paket, this.kayiplar, this.uyarilar);
  List<Map<String, dynamic>> get dersler => (paket['kategoriler'] as List)
      .expand((dynamic k) => k['egitimler'] as List)
      .cast<Map<String, dynamic>>()
      .toList();
  String get ozet => dersler
      .map((d) => '${d['kod']}: ${(d['gorevler'] as List).length} görev')
      .join(', ');
}

void _metin(
  Map<String, dynamic> veri,
  String alan,
  int sinir, {
  bool zorunlu = false,
}) {
  final deger = veri[alan];
  if (deger is! String ||
      deger.length > sinir ||
      (zorunlu && deger.trim().isEmpty)) {
    throw YuklemeHatasi(
      '$alan: ${zorunlu ? 'boş olmayan ' : ''}en fazla $sinir karakterlik metin bekleniyor.',
    );
  }
}

void _sira(dynamic deger, {int min = 0, int max = 2147483647}) {
  if (deger is! int || deger < min || deger > max) {
    throw YuklemeHatasi(
      'Sıra/görev numarası $min–$max aralığında tamsayı olmalı.',
    );
  }
}

/// Kimlikleri göndermez. API modeliyle eşleşmeyen bilgileri açıkça listeler.
YuklemePlani yuklemePlani(
  Map<String, dynamic> veri,
  Set<String> kodlar, {
  int surum = 2,
}) {
  if (surum != 1 && surum != 2) {
    throw YuklemeHatasi('Yükleme sürümü 1 veya 2 olmalı.');
  }
  if (kodlar.isEmpty) throw YuklemeHatasi('En az bir ders açıkça seçilmeli.');
  final tumDersler = (veri['egitimler'] as List).cast<Map<String, dynamic>>();
  final secilen = tumDersler.where((d) => kodlar.contains(d['kod'])).toList();
  if (secilen.length != kodlar.length) {
    throw YuklemeHatasi(
      'Seçilen ders kaynakta bulunamadı veya ders kodu yineleniyor.',
    );
  }
  final kayiplar = <String>[];
  final kategoriler = <Map<String, dynamic>>[];
  for (final kategori
      in (veri['kategoriler'] as List).cast<Map<String, dynamic>>()) {
    final dersler = secilen
        .where((d) => d['kategoriId'] == kategori['id'])
        .toList();
    if (dersler.isEmpty) continue;
    if (dersler.length > 500) {
      throw YuklemeHatasi('Bir kategoride en fazla 500 ders aktarılabilir.');
    }
    final k = <String, dynamic>{
      'kisaltma': kategori['kisaltma'],
      'ad': kategori['ad'],
      'aciklama': kategori['aciklama'] ?? '',
      'sira': kategori['sira'],
      'egitimler': dersler.map((d) => _ders(d, kayiplar, surum)).toList(),
    };
    _metin(k, 'ad', 100, zorunlu: true);
    _metin(k, 'aciklama', 500);
    if (k['kisaltma'] is! String ||
        !RegExp(r'^[A-Z][A-Z0-9-]{0,9}$').hasMatch(k['kisaltma'] as String)) {
      throw YuklemeHatasi('Geçersiz kategori kısaltması.');
    }
    _sira(k['sira']);
    kategoriler.add(k);
  }
  if (kategoriler.length > 50 ||
      kategoriler.map((k) => k['kisaltma']).toSet().length !=
          kategoriler.length ||
      kategoriler.fold<int>(0, (n, k) => n + (k['egitimler'] as List).length) !=
          secilen.length) {
    throw YuklemeHatasi(
      'Kategori ilişkisi geçersiz veya kategori sınırı aşıldı.',
    );
  }
  if ((veri['ortakDosyalar'] as Map? ?? {}).isNotEmpty) {
    kayiplar.add('ortakDosyalar: ortak kontrol programı saklanamıyor.');
  }
  final paket = <String, dynamic>{'surum': surum, 'kategoriler': kategoriler};
  if (utf8.encode(jsonEncode(paket)).length > 5 * 1024 * 1024) {
    throw YuklemeHatasi('API 5 MiB paket sınırı aşıldı.');
  }
  return YuklemePlani(
    paket,
    kayiplar,
    (veri['uyarilar'] as List? ?? []).cast<String>(),
  );
}

Map<String, dynamic> _ders(
  Map<String, dynamic> d,
  List<String> kayiplar,
  int surum,
) {
  if (surum == 2) return _dersV2(d, kayiplar);
  final kod = d['kod'];
  if (kod is! String || !RegExp(r'^[A-Z][A-Z0-9-]{0,19}$').hasMatch(kod)) {
    throw YuklemeHatasi('Geçersiz ders kodu.');
  }
  final sonuc = <String, dynamic>{
    for (final alan in [
      'kod',
      'baslik',
      'sira',
      'icerikMarkdown',
      'baslangicKodu',
      'testKodu',
    ])
      alan: d[alan],
  };
  _metin(sonuc, 'baslik', 150, zorunlu: true);
  _metin(sonuc, 'icerikMarkdown', 200000);
  _metin(sonuc, 'baslangicKodu', 100000);
  _metin(sonuc, 'testKodu', 100000);
  _sira(sonuc['sira']);
  final gorevler = (d['gorevler'] as List).cast<Map<String, dynamic>>();
  if (gorevler.length > 100 ||
      gorevler.map((g) => g['no']).toSet().length != gorevler.length) {
    throw YuklemeHatasi('$kod: görev sınırı/numaraları geçersiz.');
  }
  sonuc['gorevler'] = gorevler.map((g) {
    final sonuc = <String, dynamic>{
      for (final alan in ['no', 'baslik', 'aciklama']) alan: g[alan],
    };
    _sira(sonuc['no'], min: 1, max: 100);
    _metin(sonuc, 'baslik', 200, zorunlu: true);
    _metin(sonuc, 'aciklama', 50000);
    return sonuc;
  }).toList();
  for (final alan in ['kaynakDosyalari', 'markdownDosyalari', 'testler']) {
    final deger = d[alan];
    if ((deger is Map || deger is List) &&
        (deger as dynamic).isNotEmpty == true) {
      kayiplar.add('$kod: $alan API tarafından saklanamıyor.');
    }
  }
  for (final alan in [
    'baslangicDosyasi',
    'baslangicKodu',
    'kontrol',
    'testler',
  ]) {
    final sayi = gorevler.where((g) {
      final v = g[alan];
      return v != null && v != '' && (v is! List || v.isNotEmpty);
    }).length;
    if (sayi > 0) {
      kayiplar.add('$kod: $sayi görevde $alan ayrı alan olarak saklanamıyor.');
    }
  }
  return sonuc;
}

/// V2 tek bağımsız programı destekler; kaynak arşivi veya pytest paketi değildir.
Map<String, dynamic> _dersV2(Map<String, dynamic> d, List<String> kayiplar) {
  final sonuc = _ders(d, <String>[], 1); // Ortak DTO sınırları aynı.
  final kod = d['kod'];
  final kaynaklar = d['kaynakDosyalari'] as Map? ?? {};
  final gorevler = (d['gorevler'] as List).cast<Map<String, dynamic>>();
  if (gorevler.isEmpty) {
    throw YuklemeHatasi(
      '$kod: boş v2 görev listesi pasifleştirme riski nedeniyle reddedildi.',
    );
  }
  if ((d['testler'] as List? ?? []).isNotEmpty || d['testKodu'] != '') {
    throw YuklemeHatasi(
      '$kod: pytest kaynakları v2 stdout çalıştırıcısıyla eşdeğer değildir; surum 1 veya ayrı uyarlama gerekir.',
    );
  }
  final dosyalar = <String>{};
  sonuc['gorevler'] = gorevler.map((g) {
    final gorev = <String, dynamic>{
      for (final alan in ['no', 'baslik', 'aciklama']) alan: g[alan],
    };
    final dosya = g['baslangicDosyasi'];
    final baslangic = g['baslangicKodu'];
    if (baslangic is! String || baslangic.length > 100000) {
      throw YuklemeHatasi(
        '$kod görev ${g['no']}: başlangıç kodu eksik veya çok uzun.',
      );
    }
    if ((g['testler'] as List? ?? []).isNotEmpty) {
      throw YuklemeHatasi(
        '$kod görev ${g['no']}: pytest eşleşmesi v2 kontrolü değildir.',
      );
    }
    if (dosya == null) {
      if (baslangic != '' || g['kontrol'] != null) {
        throw YuklemeHatasi(
          '$kod görev ${g['no']}: açıklama görevi kod/kontrol içeremez.',
        );
      }
      return {
        ...gorev,
        'tur': 'aciklama',
        'baslangicDosyasi': null,
        'baslangicKodu': '',
        'kontrol': null,
      };
    }
    if (dosya is! String ||
        !RegExp(r'^gorevler/[a-zA-Z0-9_-]+\.py$').hasMatch(dosya) ||
        !dosyalar.add(dosya)) {
      throw YuklemeHatasi(
        '$kod görev ${g['no']}: güvensiz/yinelenen başlangıç dosyası.',
      );
    }
    final kaynak = kaynaklar[dosya];
    if (kaynak is! Map ||
        kaynak['kodlama'] != 'utf-8' ||
        kaynak['icerik'] != baslangic) {
      throw YuklemeHatasi(
        '$kod görev ${g['no']}: gerçek UTF-8 başlangıç dosyası bulunamadı veya görev koduyla uyuşmuyor.',
      );
    }
    if (g['kontrol'] is! Map<String, dynamic>) {
      throw YuklemeHatasi('$kod görev ${g['no']}: kontrol eksik; uydurulmadı.');
    }
    final kontrol = Map<String, dynamic>.from(g['kontrol'] as Map);
    if (kontrol['tur'] != 'standart-cikti') {
      throw YuklemeHatasi(
        '$kod görev ${g['no']}: desteklenmeyen kontrol türü.',
      );
    }
    _metin(kontrol, 'beklenenCikti', 64000);
    _metin(kontrol, 'girdi', 32000);
    _sira(kontrol['beklenenCikisKodu'], max: 255);
    final yasak = kontrol['kullanilmamali'];
    if (yasak is! List ||
        yasak.length > 30 ||
        yasak.any(
          (dynamic s) =>
              s is! String ||
              s.trim().isEmpty ||
              s.length > 100 ||
              s.contains('\n') ||
              s.contains('\r'),
        )) {
      throw YuklemeHatasi(
        '$kod görev ${g['no']}: kullanılmamalı kuralları geçersiz.',
      );
    }
    final alanlar = [
      'tur',
      'beklenenCikti',
      'girdi',
      'beklenenCikisKodu',
      'kullanilmamali',
    ];
    return {
      ...gorev,
      'tur': 'kod',
      'baslangicDosyasi': dosya,
      'baslangicKodu': baslangic,
      'kontrol': {for (final alan in alanlar) alan: kontrol[alan]},
    };
  }).toList();
  final ekDosyalar = kaynaklar.keys
      .cast<String>()
      .where((ad) => !dosyalar.contains(ad) && ad != 'ornek.py')
      .toList();
  if (ekDosyalar.isNotEmpty) {
    throw YuklemeHatasi(
      '$kod: v2 ek modül/veri/proje dosyalarını kurmaz: ${ekDosyalar.join(', ')}. Kısmi onay bu engeli kaldırmaz.',
    );
  }
  if (kaynaklar.containsKey('ornek.py')) {
    kayiplar.add(
      '$kod: ornek.py örnek programı v2 paketinde arşivlenmiyor; görev başlangıçları taşınıyor.',
    );
  }
  final markdown = d['markdownDosyalari'] as Map? ?? {};
  var birlesik = false;
  if (markdown['README.md'] is String &&
      markdown['ALISTIRMALAR.md'] is String) {
    try {
      birlesik =
          d['icerikMarkdown'] ==
          dersMetniniBirlestir(
            kod: kod,
            baslik: d['baslik'] as String,
            markdown: Map<String, String>.from(markdown),
            uyar: (_, _) {},
          );
    } on FormatException {
      // Eski JSON'un içermediği metin korunmuş sayılmaz.
    }
  }
  final ekMetinler = markdown.keys
      .where(
        (ad) =>
            !(birlesik && (ad == 'README.md' || ad == 'ALISTIRMALAR.md')) &&
            !(ad == 'ALISTIRMALAR.md' && d['icerikMarkdown'] == markdown[ad]),
      )
      .toList();
  if (ekMetinler.isNotEmpty) {
    kayiplar.add(
      '$kod: ${ekMetinler.join(', ')} ana ders içeriğine aktarılmayan ek Markdown; ayrı arşiv alanı yok.',
    );
  }
  return sonuc;
}
