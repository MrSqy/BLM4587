import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../egitim_icerik.dart' show dersKlasorleriniBul, metinOku;
import 'markdown.dart';
import 'python.dart';

export 'markdown.dart' show markdownIsle;
export 'python.dart' show testTanimlari;

String _yol(String yol) => p.split(yol).join('/');

/// Yalnızca güvenilir ders dosyalarını okur; çözüm ve sembolik bağları izlemez.
Map<String, dynamic> _dosyalariOku(Directory dizin) {
  final sonuc = <String, dynamic>{};
  void tara(Directory klasor) {
    final ogeler = klasor.listSync(followLinks: false)
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final oge in ogeler) {
      if (oge is Link) continue;
      if (oge is Directory) {
        if (!{
          'cozumler',
          '.git',
          '__pycache__',
          '.venv',
          'venv',
          'build',
          'dist',
        }.contains(p.basename(oge.path))) {
          tara(oge);
        }
      } else if (oge is File && !oge.path.endsWith('.md')) {
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

Map<String, dynamic> egitimleriAktar(String kaynak) {
  final uyarilar = <String>[];
  final egitimler = <Map<String, dynamic>>[];
  final dersNumaralari = <int>{};
  var gorevId = 0;
  for (final ders in dersKlasorleriniBul(kaynak)) {
    final kod = p.basename(ders.path);
    final sira = int.parse(kod.substring(3));
    if (!dersNumaralari.add(sira)) {
      throw FormatException(
        '$kod | ${ders.path} | Yinelenen ders sırası: $sira',
      );
    }
    void uyar(String dosya, String mesaj) =>
        uyarilar.add('$kod | ${p.join(ders.path, dosya)} | $mesaj');
    String oku(String ad, {bool zorunlu = true}) {
      final yol = p.join(ders.path, ad);
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
    if (baslikEs == null) {
      uyar(
        'README.md',
        'Başlık ders koduyla başlamıyor; kaynak başlık korundu.',
      );
    }
    final alistirmalar = oku('ALISTIRMALAR.md');
    final dosyalar = _dosyalariOku(ders);
    final testler = _testleriBul(dosyalar);
    if (testler.isEmpty) {
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
    );
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
    egitimler.add({
      'id': sira, 'kategoriId': 1, 'kod': kod, 'sira': sira,
      'baslik': baslikEs?[1] ?? baslik,
      'icerikMarkdown': markdown['ALISTIRMALAR.md'],
      'baslangicKodu': oku('calisma.py', zorunlu: false),
      // Tam test modülleri, importlar, fixture'lar ve yardımcılar korunur.
      'testKodu': dosyalar['test_alistirmalar.py']?['icerik'] ?? '',
      'gorevler': gorevler, 'markdownDosyalari': markdown,
      'kaynakDosyalari': dosyalar, 'testler': testler,
    });
  }
  final kontrol = p.join(kaynak, 'kontrol', 'kontrol.py');
  if (!File(kontrol).existsSync()) {
    uyarilar.add('PY | $kontrol | Ortak kontrol programı bulunamadı.');
  }
  return {
    'semaSurumu': 1,
    'kategoriler': [
      {'id': 1, 'ad': 'Python', 'kisaltma': 'PY', 'sira': 1},
    ],
    'egitimler': egitimler,
    'ortakDosyalar': {
      if (File(kontrol).existsSync()) 'kontrol/kontrol.py': metinOku(kontrol),
    },
    'uyarilar': uyarilar.toSet().toList(),
  };
}

void jsonYaz(String kaynak, String cikti, Map<String, dynamic> veri) {
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
) {
  final sira = int.parse(kod.substring(3));
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
      'egitimId': sira,
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
