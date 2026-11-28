import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'aktarim.dart' show guvenliCiktiYolu;
import 'api_yukleyici.dart';
import 'yukleme_plani.dart';

/// Yalnız API adaptörünün ürettiği paketi özetler; dosya zamanı kullanılmaz.
String paketOzeti(Map<String, dynamic> paket) =>
    sha256.convert(utf8.encode(jsonEncode(_sirala(paket)))).toString();

dynamic _sirala(dynamic deger, [String? alan]) {
  if (deger is Map) {
    final anahtarlar = deger.keys.cast<String>().toList()..sort();
    return {for (final k in anahtarlar) k: _sirala(deger[k], k)};
  }
  if (deger is List) {
    final liste = deger.map((v) => _sirala(v)).toList();
    if (alan == 'gorevler') {
      liste.sort(
        (dynamic a, dynamic b) => (a['no'] as int).compareTo(b['no'] as int),
      );
    } else if (alan == 'kullanilmamali') {
      liste.sort(
        (dynamic a, dynamic b) => (a as String).compareTo(b as String),
      );
    }
    return liste;
  }
  // Kod, Markdown ve stdout içindeki boşluk/satır sonları anlamlıdır.
  return deger;
}

String _hedefAnahtari(Uri hedef) => sha256
    .convert(
      utf8.encode(apiAdresi(hedef.toString()).normalizePath().toString()),
    )
    .toString();

class ArtimliDers {
  final YuklemePlani plan;
  final String durum;
  ArtimliDers(this.plan, this.durum);
  String get kod => plan.dersler.single['kod'] as String;
}

/// Sırlar ve kaynak kod saklanmaz. Her hedefin doğrulanmış ders kayıtları ayrıdır.
class ArtimliDurum {
  final File dosya;
  Map<String, dynamic> _hedefler = {};
  ArtimliDurum(String yol, {required String kaynak})
    : dosya = File(guvenliCiktiYolu(kaynak, yol));

  void oku() {
    _hedefler = {};
    if (FileSystemEntity.typeSync(dosya.path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw YuklemeHatasi('Durum dosyası sembolik bağlantı olamaz.');
    }
    if (!dosya.existsSync()) return;
    try {
      if (dosya.lengthSync() > 8 * 1024 * 1024) throw const FormatException();
      final veri = jsonDecode(dosya.readAsStringSync(encoding: utf8));
      if (veri is! Map || veri['semaSurumu'] != 1 || veri['hedefler'] is! Map) {
        throw const FormatException();
      }
      final hedefler = Map<String, dynamic>.from(veri['hedefler'] as Map);
      for (final hedef in hedefler.entries) {
        if (!_hashGecerli(hedef.key) || hedef.value is! Map) {
          throw const FormatException();
        }
        for (final dynamic kayit in (hedef.value as Map).entries) {
          if (kayit.key is! String ||
              !RegExp(
                r'^[A-Z][A-Z0-9-]{0,19}$',
              ).hasMatch(kayit.key as String) ||
              kayit.value is! Map ||
              !_hashGecerli(kayit.value['ozet']) ||
              kayit.value['kategori'] is! Map) {
            throw const FormatException();
          }
          final k = kayit.value['kategori'] as Map;
          if (k['kisaltma'] is! String ||
              k['ad'] is! String ||
              k['aciklama'] is! String ||
              k['sira'] is! int) {
            throw const FormatException();
          }
        }
      }
      _hedefler = hedefler;
    } on FormatException {
      throw YuklemeHatasi(
        '${dosya.path}: geçersiz veya desteklenmeyen durum kaydı; üzerine yazılmadı.',
      );
    } on TypeError {
      throw YuklemeHatasi(
        '${dosya.path}: geçersiz durum yapısı; üzerine yazılmadı.',
      );
    }
  }

  bool _hashGecerli(dynamic value) =>
      value is String && RegExp(r'^[a-f0-9]{64}$').hasMatch(value);

  List<ArtimliDers> ayir(YuklemePlani plan, Uri hedef) {
    final kayitlar = _hedefler[_hedefAnahtari(hedef)] as Map? ?? {};
    final sonuc = <ArtimliDers>[];
    for (final dynamic kategori in plan.paket['kategoriler']) {
      for (final dynamic ders in kategori['egitimler']) {
        final kayit = kayitlar[ders['kod']] as Map?;
        // Tam aktarım da mevcut PY kategori metadatasını kaynaktan değiştirmez.
        // Son gerçek gönderimde korunan değerler, çevrimdışı karşılaştırmada kullanılır.
        final etkiliKategori = Map<String, dynamic>.from(kategori as Map);
        if (kayit != null &&
            kategori['kisaltma'] != 'TM-DEMO' &&
            kayit['kategori']['kisaltma'] == kategori['kisaltma']) {
          for (final alan in ['ad', 'aciklama', 'sira']) {
            etkiliKategori[alan] = kayit['kategori'][alan];
          }
        }
        etkiliKategori['egitimler'] = [ders];
        final tekPaket =
            jsonDecode(
                  jsonEncode({
                    'surum': plan.paket['surum'],
                    'kategoriler': [etkiliKategori],
                  }),
                )
                as Map<String, dynamic>;
        final tekPlan = YuklemePlani(tekPaket, plan.kayiplar, plan.uyarilar);
        final durum = kayit == null
            ? 'yeni'
            : kayit['ozet'] == paketOzeti(tekPaket)
            ? 'degismemis'
            : 'degismis';
        sonuc.add(ArtimliDers(tekPlan, durum));
      }
    }
    return sonuc;
  }

  void dogrulandi(Uri hedef, YuklemePlani gonderilen) {
    final kategori = (gonderilen.paket['kategoriler'] as List).single as Map;
    final ders = gonderilen.dersler.single;
    final key = _hedefAnahtari(hedef);
    final kayitlar = Map<String, dynamic>.from(_hedefler[key] as Map? ?? {});
    kayitlar[ders['kod'] as String] = {
      'ozet': paketOzeti(gonderilen.paket),
      'kategori': {
        for (final alan in ['kisaltma', 'ad', 'aciklama', 'sira'])
          alan: kategori[alan],
      },
    };
    _hedefler[key] = kayitlar;
    _yaz();
  }

  void _yaz() {
    final gecici = File(
      '${dosya.path}.$pid.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    try {
      gecici.writeAsStringSync(
        '${jsonEncode({'semaSurumu': 1, 'hedefler': _hedefler})}\n',
        encoding: utf8,
        flush: true,
      );
      gecici.renameSync(dosya.path);
    } finally {
      if (gecici.existsSync()) gecici.deleteSync();
    }
  }

  /// Gerçek aktarımlar aynı durum dosyasını eşzamanlı güncelleyemez.
  /// Dry-run bu metodu çağırmaz; kilit dosyası bile oluşturmaz.
  Future<T> kilitli<T>(Future<T> Function() islem) async {
    dosya.parent.createSync(recursive: true);
    final kilitYolu = '${dosya.path}.kilit';
    if (FileSystemEntity.typeSync(kilitYolu, followLinks: false) ==
        FileSystemEntityType.link) {
      throw YuklemeHatasi('Durum kilidi sembolik bağlantı olamaz.');
    }
    final kilit = File(kilitYolu).openSync(mode: FileMode.append);
    try {
      try {
        kilit.lockSync();
      } on FileSystemException {
        throw YuklemeHatasi(
          'Durum dosyası başka bir aktarım tarafından kullanılıyor.',
        );
      }
      return await islem();
    } finally {
      kilit.closeSync();
    }
  }
}

void artimliOzeti(List<ArtimliDers> dersler, void Function(String) yaz) {
  for (final ders in dersler) {
    yaz(switch (ders.durum) {
      'yeni' =>
        'YÜKLENECEK ${ders.kod}: yeni (bu hedefte doğrulanmış yerel kayıt yok).',
      'degismis' => 'YÜKLENECEK ${ders.kod}: değişmiş.',
      _ => 'ATLANACAK ${ders.kod}: değişmemiş.',
    });
  }
  yaz(
    'Artımlı: ${dersler.where((d) => d.durum != 'degismemis').length} yüklenecek, '
    '${dersler.where((d) => d.durum == 'degismemis').length} atlanacak.',
  );
}

class ArtimliYukleyici {
  final IcerikYukleyici yukleyici;
  final ArtimliDurum durum;
  ArtimliYukleyici(this.yukleyici, this.durum);

  Future<bool> yukle(
    YuklemePlani plan, {
    required String eposta,
    required String sifre,
    required void Function(String) yaz,
    bool kayipOnayi = false,
    bool v2GecisOnayi = false,
  }) => durum.kilitli(() async {
    durum.oku();
    final dersler = durum.ayir(plan, yukleyici.temel);
    artimliOzeti(dersler, yaz);
    for (final ders in dersler.where((d) => d.durum != 'degismemis')) {
      final sonuc = await yukleyici.yukle(
        ders.plan,
        eposta: eposta,
        sifre: sifre,
        kayipOnayi: kayipOnayi,
        v2GecisOnayi: v2GecisOnayi,
      );
      yaz('${ders.kod}: ${sonuc.ozet}');
      if (!sonuc.basarili ||
          !sonuc.kayitOnaylandi ||
          !sonuc.dogrulanan.contains(ders.kod)) {
        if (sonuc.hata != null) yaz('Hata: ${sonuc.hata}');
        yaz(
          'Artımlı aktarım durdu; bu ders ve sonraki dersler güncel işaretlenmedi. Otomatik tekrar yapılmadı.',
        );
        return false;
      }
      // Ön kontrolün koruduğu gerçek kategori değerleri de artık pakettedir.
      durum.dogrulandi(yukleyici.temel, ders.plan);
    }
    yaz(
      'Artımlı aktarım tamamlandı. Değişmemiş dersler için yükleme isteği gönderilmedi.',
    );
    return true;
  });
}
