import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

/// Tanınan iki kaynak biçimi. Kategori ve sıra demo paketinden okunur.
class KaynakDuzeni {
  static const manifestAdi = 'teknik-mulakat-v2.json';
  final String kaynak;
  final Map<String, dynamic>? manifest;
  final Map<String, dynamic> kategori;
  final List<Map<String, dynamic>> dersler;
  bool get teknik => manifest != null;

  KaynakDuzeni._(this.kaynak, this.manifest, this.kategori, this.dersler);

  factory KaynakDuzeni(String kaynak) {
    final yol = p.join(kaynak, manifestAdi);
    if (!File(yol).existsSync()) {
      final dersler = Directory(p.join(kaynak, 'dersler'));
      if (dersler.existsSync() &&
          dersler
              .listSync(followLinks: false)
              .any((e) => p.basename(e.path).startsWith('TM-DEMO-'))) {
        throw FormatException(
          '$yol | TM-DEMO dersleri için kaynak manifesti eksik.',
        );
      }
      return KaynakDuzeni._(kaynak, null, {
        'id': 1,
        'ad': 'Python',
        'kisaltma': 'PY',
        'sira': 1,
      }, []);
    }
    void hata(String mesaj) => throw FormatException('$yol | $mesaj');
    if (FileSystemEntity.typeSync(yol, followLinks: false) ==
        FileSystemEntityType.link) {
      hata('Manifest sembolik bağlantı olamaz.');
    }
    final dynamic veri;
    try {
      veri = jsonDecode(utf8.decode(File(yol).readAsBytesSync()));
    } on FormatException {
      hata('Geçerli UTF-8 JSON manifesti bekleniyor.');
      rethrow;
    }
    if (veri is! Map<String, dynamic>) hata('Manifest nesne olmalı.');
    final m = veri as Map<String, dynamic>;
    _alanlar(m, {'surum', 'kategoriler'}, yol);
    if (m['surum'] != 2 ||
        m['kategoriler'] is! List ||
        (m['kategoriler'] as List).length != 1) {
      hata('Tek TM-DEMO kategorisi içeren v2 kaynak paketi gerekiyor.');
    }
    final dynamic k = (m['kategoriler'] as List).single;
    if (k is! Map<String, dynamic>) hata('Kategori nesne olmalı.');
    final kategori = k as Map<String, dynamic>;
    _alanlar(kategori, {
      'kisaltma',
      'ad',
      'aciklama',
      'sira',
      'egitimler',
    }, yol);
    if (kategori['kisaltma'] != 'TM-DEMO' ||
        kategori['ad'] is! String ||
        kategori['aciklama'] is! String ||
        kategori['sira'] is! int ||
        kategori['egitimler'] is! List ||
        (kategori['egitimler'] as List).isEmpty) {
      hata('TM-DEMO kategori metadatası eksik veya geçersiz.');
    }
    final dersler = <Map<String, dynamic>>[];
    final kodlar = <String>{}, siralar = <int>{};
    for (final dynamic d in kategori['egitimler'] as List) {
      if (d is! Map<String, dynamic>) hata('Ders nesne olmalı.');
      final ders = d as Map<String, dynamic>;
      _alanlar(ders, {
        'kod',
        'baslik',
        'sira',
        'icerikMarkdown',
        'baslangicKodu',
        'testKodu',
        'gorevler',
      }, yol);
      final kod = ders['kod'];
      if (kod is! String ||
          !RegExp(r'^TM-DEMO-\d+$').hasMatch(kod) ||
          kod.length > 20 ||
          !kodlar.add(kod) ||
          ders['sira'] is! int ||
          (ders['sira'] as int) < 0 ||
          !siralar.add(ders['sira'] as int) ||
          ders['baslik'] is! String ||
          ders['icerikMarkdown'] is! String ||
          ders['baslangicKodu'] != '' ||
          ders['testKodu'] != '' ||
          ders['gorevler'] is! List ||
          (ders['gorevler'] as List).isEmpty) {
        hata(
          '$kod: geçersiz/yinelenen kod-sıra veya desteklenmeyen ders kod/test alanı.',
        );
      }
      final numaralar = <int>{};
      for (final dynamic g in ders['gorevler'] as List) {
        if (g is! Map<String, dynamic>) hata('$kod: görev nesne olmalı.');
        final gorev = g as Map<String, dynamic>;
        _alanlar(gorev, {
          'no',
          'baslik',
          'aciklama',
          'tur',
          'baslangicDosyasi',
          'baslangicKodu',
          'kontrol',
        }, '$yol | $kod');
        if (gorev['no'] is! int ||
            !numaralar.add(gorev['no'] as int) ||
            gorev['baslik'] is! String ||
            gorev['aciklama'] is! String ||
            !{'kod', 'aciklama'}.contains(gorev['tur']) ||
            gorev['baslangicKodu'] is! String) {
          hata('$kod: görev numarası/türü/metni geçersiz veya yineleniyor.');
        }
        if (gorev['kontrol'] is Map<String, dynamic>) {
          _alanlar(gorev['kontrol'] as Map<String, dynamic>, {
            'tur',
            'beklenenCikti',
            'girdi',
            'beklenenCikisKodu',
            'kullanilmamali',
          }, '$yol | $kod görev ${gorev['no']}');
        }
      }
      dersler.add(ders);
    }
    dersler.sort((a, b) => (a['sira'] as int).compareTo(b['sira'] as int));
    return KaynakDuzeni._(kaynak, m, {
      'id': 2,
      for (final alan in ['kisaltma', 'ad', 'aciklama', 'sira'])
        alan: kategori[alan],
    }, dersler);
  }

  List<Directory> klasorler() {
    final dizin = Directory(p.join(kaynak, 'dersler'));
    if (!dizin.existsSync()) {
      throw FileSystemException('Dersler klasörü bulunamadı.', dizin.path);
    }
    if (teknik &&
        FileSystemEntity.typeSync(dizin.path, followLinks: false) ==
            FileSystemEntityType.link) {
      throw FormatException('${dizin.path} | Sembolik dersler dizini okunmaz.');
    }
    final desen = RegExp(teknik ? r'^TM-DEMO-(\d+)$' : r'^PY-(\d+)$');
    final bulunan = dizin
        .listSync(followLinks: false)
        .whereType<Directory>()
        .where((d) => desen.hasMatch(p.basename(d.path)))
        .toList();
    if (teknik) {
      final beklenen = dersler.map((d) => d['kod'] as String).toSet();
      final gercek = bulunan.map((d) => p.basename(d.path)).toSet();
      if (beklenen.difference(gercek).isNotEmpty ||
          gercek.difference(beklenen).isNotEmpty) {
        throw FormatException(
          '${dizin.path} | $manifestAdi | Manifest/klasör uyuşmazlığı: eksik ${beklenen.difference(gercek)}, tanımsız ${gercek.difference(beklenen)}',
        );
      }
      bulunan.sort(
        (a, b) => sira(p.basename(a.path)).compareTo(sira(p.basename(b.path))),
      );
    } else {
      bulunan.sort((a, b) {
        final fark = sira(
          p.basename(a.path),
        ).compareTo(sira(p.basename(b.path)));
        return fark != 0 ? fark : a.path.compareTo(b.path);
      });
    }
    return bulunan;
  }

  Map<String, dynamic> ders(String kod) =>
      dersler.singleWhere((d) => d['kod'] == kod);
  int sira(String kod) =>
      teknik ? ders(kod)['sira'] as int : int.parse(kod.substring(3));
  // Dışa aktarım içi geçici kimlikler; API'ye gönderilmezler.
  int dersId(String kod) => teknik ? 1000000 + sira(kod) : sira(kod);
}

void _alanlar(Map<String, dynamic> veri, Set<String> beklenen, String yol) {
  if (veri.keys.toSet().difference(beklenen).isNotEmpty ||
      beklenen.difference(veri.keys.toSet()).isNotEmpty) {
    throw FormatException(
      '$yol | Eksik/desteklenmeyen manifest alanları: ${beklenen.difference(veri.keys.toSet())} / ${veri.keys.toSet().difference(beklenen)}',
    );
  }
}

/// Kaynak JSON'u ile düzenlenebilir öğrenci dosyaları çelişirse aktarım durur.
void teknikDersiDogrula(
  KaynakDuzeni duzen,
  String kod,
  String baslik,
  String readme,
  List<Map<String, dynamic>> gorevler,
) {
  final yol = p.join(duzen.kaynak, KaynakDuzeni.manifestAdi);
  Never hata(String alan) => throw FormatException(
    '$kod | $yol | Markdown/başlangıç/manifest uyuşmazlığı: $alan',
  );
  final kaynak = duzen.ders(kod);
  if (baslik != kaynak['baslik'] ||
      !readme.contains((kaynak['icerikMarkdown'] as String).trim())) {
    hata('başlık/konu anlatımı');
  }
  final listedeki = (kaynak['gorevler'] as List).cast<Map<String, dynamic>>();
  if (listedeki.length != gorevler.length) hata('görev sayısı');
  for (final gorev in gorevler) {
    final es = listedeki.where((g) => g['no'] == gorev['no']).toList();
    if (es.length != 1) hata('görev ${gorev['no']}');
    final g = es.single;
    for (final alan in ['baslik', 'baslangicDosyasi', 'baslangicKodu']) {
      if (gorev[alan] != g[alan]) hata('görev ${g['no']} $alan');
    }
    if ((gorev['baslangicDosyasi'] == null ? 'aciklama' : 'kod') != g['tur']) {
      hata('görev ${g['no']} tür');
    }
    if (g['kontrol'] == null) {
      if (gorev['kontrol'] != null) hata('görev ${g['no']} kontrol');
    } else {
      if (g['kontrol'] is! Map || gorev['kontrol'] is! Map) {
        hata('görev ${g['no']} kontrol');
      }
      for (final alan in [
        'tur',
        'beklenenCikti',
        'girdi',
        'beklenenCikisKodu',
        'kullanilmamali',
      ]) {
        if (jsonEncode(g['kontrol'][alan]) !=
            jsonEncode(gorev['kontrol'][alan])) {
          hata('görev ${g['no']} kontrol.$alan');
        }
      }
    }
    // Paket, açıklama görevlerine ayrıca otomatik değerlendirme notu ekler.
    final ek = (g['aciklama'] as String).trim();
    if (ek.isNotEmpty && !(gorev['aciklama'] as String).contains(ek)) {
      gorev['aciklama'] =
          '${gorev['aciklama']}\n\n#### Kaynak paket açıklaması\n\n$ek';
    }
  }
}
