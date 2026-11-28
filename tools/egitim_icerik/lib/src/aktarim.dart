import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../egitim_icerik.dart' show metinOku;
import 'kaynak_duzeni.dart';
import 'markdown.dart';
import 'icerik_birlestir.dart';
import 'python.dart';

export 'markdown.dart' show markdownIsle;
export 'python.dart' show testTanimlari;

String _yol(String yol) => p.split(yol).join('/');

/// Yalnızca güvenilir ders dosyalarını okur; çözüm ve sembolik bağları izlemez.
Map<String, dynamic> _dosyalariOku(
  Directory dizin, {
  bool markdownDahil = false,
}) {
  final sonuc = <String, dynamic>{};
  void tara(Directory klasor) {
    final ogeler = klasor.listSync(followLinks: false)
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final oge in ogeler) {
      if (oge is Link) {
        if (markdownDahil) {
          throw FormatException('${oge.path} | Sembolik kaynak bağı okunmaz.');
        }
        continue;
      }
      if (oge is Directory) {
        if (!{
          'cozumler',
          'çözümler',
          'solutions',
          '.git',
          '__pycache__',
          '.venv',
          'venv',
          'build',
          'dist',
        }.contains(p.basename(oge.path).toLowerCase())) {
          tara(oge);
        }
      } else if (oge is File &&
          !{
            'cevaplar.md',
            'referans.py',
          }.contains(p.basename(oge.path).toLowerCase()) &&
          (markdownDahil || !oge.path.toLowerCase().endsWith('.md'))) {
        final veri = oge.readAsBytesSync();
        final yol = _yol(p.relative(oge.path, from: dizin.path));
        try {
          sonuc[yol] = {'kodlama': 'utf-8', 'icerik': utf8.decode(veri)};
        } on FormatException {
          sonuc[yol] = {'kodlama': 'base64', 'icerik': base64Encode(veri)};
        }
      }
    }
  }

  tara(dizin);
  return sonuc;
}

Map<String, dynamic> egitimleriAktar(
  String kaynak, {
  Set<String>? dersKodlari,
}) {
  final uyarilar = <String>[];
  final egitimler = <Map<String, dynamic>>[];
  final dersNumaralari = <int>{};
  var gorevId = 0;
  final duzen = KaynakDuzeni(kaynak);
  final bulunan = duzen.klasorler();
  if (dersKodlari != null) {
    final eksik = dersKodlari.difference(
      bulunan.map((d) => p.basename(d.path)).toSet(),
    );
    if (eksik.isNotEmpty || dersKodlari.isEmpty) {
      throw FormatException(
        'Ders seçimi boş veya kaynakta bulunamadı: ${eksik.join(', ')}',
      );
    }
  }
  for (final ders in bulunan) {
    final kod = p.basename(ders.path);
    if (dersKodlari != null && !dersKodlari.contains(kod)) continue;
    final sira = duzen.sira(kod);
    final egitimId = duzen.dersId(kod);
    if (!dersNumaralari.add(sira)) {
      throw FormatException(
        '$kod | ${ders.path} | Yinelenen ders sırası: $sira',
      );
    }
    void uyar(String dosya, String mesaj) =>
        uyarilar.add('$kod | ${p.join(ders.path, dosya)} | $mesaj');
    String oku(String ad, {bool zorunlu = true}) {
      final yol = p.join(ders.path, ad);
      if (duzen.teknik &&
          FileSystemEntity.typeSync(yol, followLinks: false) ==
              FileSystemEntityType.link) {
        throw FormatException('$kod | $yol | Sembolik kaynak dosyası okunmaz.');
      }
      if (!File(yol).existsSync()) {
        if (zorunlu) {
          throw FormatException('$kod | $yol | Gerekli dosya bulunamadı.');
        }
        return '';
      }
      return metinOku(yol);
    }

    final readme = oku('README.md');
    final baslik = RegExp(
      r'^#\s+(.+)$',
      multiLine: true,
    ).firstMatch(kodBloklariniMaskele(readme))?[1];
    if (baslik == null) {
      throw FormatException(
        '$kod | ${ders.path}/README.md | Ders başlığı bulunamadı.',
      );
    }
    final baslikDeseni = RegExp('^${RegExp.escape(kod)}\\s*[—–-]\\s*(.+)');
    final baslikEs = baslikDeseni.firstMatch(baslik);
    if (baslikEs == null && !duzen.teknik) {
      uyar(
        'README.md',
        'Başlık ders koduyla başlamıyor; kaynak başlık korundu.',
      );
    }
    final alistirmalar = oku('ALISTIRMALAR.md');
    final tumDosyalar = _dosyalariOku(ders, markdownDahil: duzen.teknik);
    final dosyalar = <String, dynamic>{
      for (final e in tumDosyalar.entries)
        if (!e.key.toLowerCase().endsWith('.md')) e.key: e.value,
    };
    final testler = _testleriBul(dosyalar);
    if (testler.isEmpty && !duzen.teknik) {
      uyar(
        'ALISTIRMALAR.md',
        'test_gorev_N tanımı yok; mevcut çıktı kontrolleri saklandı, test üretilmedi.',
      );
    }
    final gorevler = _gorevleriOku(
      kod,
      ders,
      alistirmalar,
      dosyalar,
      testler,
      () => ++gorevId,
      uyar,
      egitimId,
    );
    if (duzen.teknik) {
      teknikDersiDogrula(duzen, kod, baslikEs?[1] ?? baslik, readme, gorevler);
    }
    final markdown = <String, String>{};
    for (final ad in [
      'README.md',
      'ALISTIRMALAR.md',
      'LAB.md',
      'TROUBLESHOOTING.md',
    ]) {
      final ham = ad == 'README.md'
          ? readme
          : ad == 'ALISTIRMALAR.md'
          ? alistirmalar
          : oku(ad, zorunlu: false);
      if (ham.isNotEmpty) markdown[ad] = markdownIsle(ham, (m) => uyar(ad, m));
    }
    if (duzen.teknik) {
      for (final e in tumDosyalar.entries.where(
        (e) =>
            e.key.toLowerCase().endsWith('.md') && !markdown.containsKey(e.key),
      )) {
        if (e.value['kodlama'] != 'utf-8') {
          throw FormatException(
            '$kod | ${p.join(ders.path, e.key)} | Markdown UTF-8 olmalı.',
          );
        }
        markdown[e.key] = markdownIsle(
          e.value['icerik'] as String,
          (m) => uyar(e.key, m),
        );
      }
      if (alistirmalar.contains('<details>')) {
        uyar(
          'ALISTIRMALAR.md',
          'Kendini kontrol et bölümleri kaynak öğrenci metni olarak korundu; HTML details gösterimi görüntüleyiciye bağlıdır. Çözüm dosyaları okunmaz.',
        );
      }
    }
    egitimler.add({
      'id': egitimId,
      'kategoriId': duzen.kategori['id'],
      'kod': kod,
      'sira': sira,
      'baslik': baslikEs?[1] ?? baslik,
      'icerikMarkdown': dersMetniniBirlestir(
        kod: kod,
        baslik: baslikEs?[1] ?? baslik,
        markdown: markdown,
        uyar: uyar,
      ),
      'baslangicKodu': oku('calisma.py', zorunlu: false),
      // Tam test modülleri, importlar, fixture'lar ve yardımcılar korunur.
      'testKodu': dosyalar['test_alistirmalar.py']?['icerik'] ?? '',
      'gorevler': gorevler, 'markdownDosyalari': markdown,
      'kaynakDosyalari': dosyalar, 'testler': testler,
    });
  }
  final kontrolAdi = duzen.teknik ? 'kontrol.py' : 'kontrol/kontrol.py';
  final kontrol = p.join(kaynak, p.fromUri(kontrolAdi));
  if (duzen.teknik &&
      FileSystemEntity.typeSync(kontrol, followLinks: false) ==
          FileSystemEntityType.link) {
    throw FormatException('$kontrol | Sembolik kontrol dosyası okunmaz.');
  }
  if (!File(kontrol).existsSync()) {
    uyarilar.add(
      '${duzen.kategori['kisaltma']} | $kontrol | Ortak kontrol programı bulunamadı.',
    );
  }
  if (duzen.teknik) {
    for (final oge in Directory(kaynak).listSync(followLinks: false)) {
      if (oge is Link ||
          (oge is File &&
              !{
                'README.md',
                'NOTICE.md',
                'LICENSE',
                'LICENSE-CODE',
                'kontrol.py',
                KaynakDuzeni.manifestAdi,
              }.contains(p.basename(oge.path)))) {
        throw FormatException(
          '${oge.path} | Tanımsız kök dosyası/bağı; sessizce dışarıda bırakılmadı.',
        );
      }
    }
  }
  return {
    'semaSurumu': 1,
    'kategoriler': [duzen.kategori],
    'egitimler': egitimler,
    'ortakDosyalar': {
      if (File(kontrol).existsSync()) kontrolAdi: metinOku(kontrol),
    },
    if (duzen.teknik)
      'ekBelgeler': {
        for (final ad in ['README.md', 'NOTICE.md', 'LICENSE', 'LICENSE-CODE'])
          if (File(p.join(kaynak, ad)).existsSync())
            ad: metinOku(p.join(kaynak, ad)),
      },
    'uyarilar': uyarilar.toSet().toList(),
  };
}

String guvenliCiktiYolu(String kaynak, String cikti) {
  final kok = Directory(kaynak).resolveSymbolicLinksSync();
  final dosya = File(p.absolute(cikti));
  // Var olmayan hedeflerde en yakın mevcut üst dizinin gerçek yolunu kullan.
  String gercek(String yol) {
    if (FileSystemEntity.typeSync(yol) != FileSystemEntityType.notFound) {
      return FileSystemEntity.isDirectorySync(yol)
          ? Directory(yol).resolveSymbolicLinksSync()
          : File(yol).resolveSymbolicLinksSync();
    }
    return p.join(gercek(p.dirname(yol)), p.basename(yol));
  }

  final hedef = gercek(dosya.path);
  if (p.equals(kok, hedef) || p.isWithin(kok, hedef)) {
    throw FileSystemException(
      'JSON kaynak eğitim klasörüne yazılamaz.',
      dosya.path,
    );
  }
  return dosya.path;
}

void jsonYaz(String kaynak, String cikti, Map<String, dynamic> veri) {
  final dosya = File(guvenliCiktiYolu(kaynak, cikti));
  dosya.parent.createSync(recursive: true);
  dosya.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(veri)}\n',
    encoding: utf8,
  );
}

List<Map<String, dynamic>> _testleriBul(Map<String, dynamic> dosyalar) {
  final testler = <Map<String, dynamic>>[];
  for (final dosya in dosyalar.entries) {
    if (!dosya.key.endsWith('.py') || dosya.value['kodlama'] != 'utf-8') {
      continue;
    }
    for (final test in testTanimlari(dosya.value['icerik'] as String)) {
      testler.add({...test, 'dosya': dosya.key});
    }
  }

  return testler;
}

List<Map<String, dynamic>> _gorevleriOku(
  String kod,
  Directory ders,
  String alistirmalar,
  Map<String, dynamic> dosyalar,
  List<Map<String, dynamic>> testler,
  int Function() yeniId,
  void Function(String, String) uyar,
  int egitimId,
) {
  final maskeli = kodBloklariniMaskele(alistirmalar);
  final bolumler = RegExp(
    r'^#{2,3}\s+Görev\s+(\d+)\s*[—–-]\s*(.+)$',
    multiLine: true,
  ).allMatches(maskeli).toList();
  if (bolumler.isEmpty) {
    throw FormatException(
      '$kod | ${ders.path}/ALISTIRMALAR.md | Görev başlıkları bulunamadı.',
    );
  }
  final gorevler = <Map<String, dynamic>>[];
  final numaralar = <int>{};
  for (var i = 0; i < bolumler.length; i++) {
    final bolum = bolumler[i];
    final no = int.parse(bolum[1]!);
    if (!numaralar.add(no)) {
      throw FormatException(
        '$kod | ${ders.path}/ALISTIRMALAR.md | Yinelenen görev: $no',
      );
    }
    final metin = alistirmalar
        .substring(
          bolum.end,
          i + 1 < bolumler.length ? bolumler[i + 1].start : alistirmalar.length,
        )
        .trim();
    final duz = kodBloklariniMaskele(metin);
    final dosya = RegExp(
      r'^\*\*Dosya:\*\*\s*`([^`]+)`',
      multiLine: true,
    ).firstMatch(duz)?[1];
    if (dosya != null &&
        (!dosya.startsWith('gorevler/') ||
            p.posix.normalize(dosya) != dosya ||
            dosya.contains('\\'))) {
      throw FormatException(
        '$kod | ${ders.path}/ALISTIRMALAR.md | Güvensiz görev dosyası: $dosya',
      );
    }
    if (dosya != null && !dosyalar.containsKey(dosya)) {
      uyar(dosya, 'Görev $no başlangıç dosyası bulunamadı.');
    }
    String? blok(String etiket) {
      final yer = RegExp(
        '^\\*\\*${RegExp.escape(etiket)}:\\*\\*[ \\t]*\$',
        multiLine: true,
      ).firstMatch(duz);
      if (yer == null) return null;
      final es = RegExp(
        r'^\s*```text[^\S\n]*\n([\s\S]*?)^```[^\S\n]*$',
        multiLine: true,
      ).matchAsPrefix(metin.substring(yer.end));
      if (es == null) {
        uyar(
          'ALISTIRMALAR.md',
          'Görev $no: $etiket text bloğu ayrıştırılamadı.',
        );
      }
      return es?[1];
    }

    final beklenen = blok('Beklenen çıktı');
    if (dosya != null && beklenen == null) {
      uyar('ALISTIRMALAR.md', 'Görev $no için beklenen çıktı bulunamadı.');
    }
    final eslesen = testler.where((t) => t['no'] == no).toList();
    if (testler.isNotEmpty && dosya != null && eslesen.isEmpty) {
      uyar('ALISTIRMALAR.md', 'Görev $no için test_gorev_N eşleşmesi yok.');
    }
    final cikis = RegExp(
      r'^\*\*Beklenen çıkış kodu:\*\*\s*`(\d+)`',
      multiLine: true,
    ).firstMatch(duz);
    if (duz.contains('**Beklenen çıkış kodu:**') && cikis == null) {
      uyar('ALISTIRMALAR.md', 'Görev $no çıkış kodu ayrıştırılamadı.');
    }
    final yasak = RegExp(
      r'^\*\*Kullanılmamalı:\*\*(.*)$',
      multiLine: true,
    ).firstMatch(duz)?[1];
    gorevler.add({
      'id': yeniId(),
      'egitimId': egitimId,
      'no': no,
      'baslik': bolum[2]!,
      'aciklama': markdownIsle(metin, (m) => uyar('ALISTIRMALAR.md', m)),
      'baslangicDosyasi': dosya,
      'baslangicKodu': dosya == null ? '' : dosyalar[dosya]?['icerik'] ?? '',
      'testler': eslesen,
      'kontrol': dosya == null
          ? null
          : {
              'tur': 'standart-cikti',
              'beklenenCikti': beklenen,
              'girdi': blok('Girdi') ?? '',
              'beklenenCikisKodu': cikis == null ? 0 : int.parse(cikis[1]!),
              'kullanilmamali': yasak == null
                  ? <String>[]
                  : RegExp(
                      r'`([^`]+)`',
                    ).allMatches(yasak).map((m) => m[1]!).toList(),
            },
    });
  }
  for (final test in testler) {
    if (!numaralar.contains(test['no'])) {
      uyar(test['dosya'] as String, '${test['ad']} hiçbir görevle eşleşmedi.');
    }
  }

  return gorevler;
}
