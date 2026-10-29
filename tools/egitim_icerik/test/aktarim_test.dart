import 'dart:convert';
import 'dart:io';
import 'package:egitim_icerik/egitim_icerik.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory kaynak;
  late Directory cikti;
  void yaz(String yol, String metin) {
    final dosya = File(p.join(kaynak.path, yol));
    dosya.parent.createSync(recursive: true);
    dosya.writeAsStringSync(metin, encoding: utf8);
  }

  void ders({String? gorevler}) {
    yaz(
      'dersler/PY-01/README.md',
      '# PY-01 — Türkçe başlık\n> [!info] Ön bilgi\n> Oku.\n',
    );
    yaz(
      'dersler/PY-01/ALISTIRMALAR.md',
      gorevler ??
          '''# Görevler
## Görev 1 — İlk görev
**Dosya:** `gorevler/ilk.py`
**Girdi:**
```text
Çağla
```
**Beklenen çıktı:**
```text
Merhaba, Çağla!
```
**Kullanılmamalı:** `eval`, `exec`
## Görev 2 — Açıkla
Bir cümle yaz.
''',
    );
    yaz(
      'dersler/PY-01/gorevler/ilk.py',
      'from yardimci import selam\n# TODO\n',
    );
    yaz('dersler/PY-01/gorevler/yardimci.py', 'def selam(): pass\n');
    yaz('kontrol/kontrol.py', '# ortak kontrol\n');
  }

  setUp(() {
    kaynak = Directory.systemTemp.createTempSync('aktarim_kaynak_');
    cikti = Directory.systemTemp.createTempSync('aktarim_cikti_');
  });

  test('CLI yardım, eski listeleme, JSON üretimi ve hata kodları', () {
    ders();
    ProcessResult calistir(List<String> argumanlar) => Process.runSync(
      Platform.resolvedExecutable,
      ['run', 'bin/egitim_icerik.dart', ...argumanlar],
    );
    expect(calistir(['--help']).exitCode, 0);
    final liste = calistir([kaynak.path]);
    expect(liste.exitCode, 0);
    expect(liste.stdout, contains('Toplam 1 ders'));
    final hedef = p.join(cikti.path, 'cli.json');
    expect(calistir([kaynak.path, hedef]).exitCode, 0);
    expect(
      (jsonDecode(File(hedef).readAsStringSync()) as Map)['egitimler'],
      hasLength(1),
    );
    expect(calistir([]).exitCode, 1);
    expect(
      calistir([kaynak.path, p.join(kaynak.path, 'yasak.json')]).exitCode,
      1,
    );
  });

  test('Bozuk kontrol bloğu sonraki alanın değerini ödünç almaz', () {
    ders(
      gorevler:
          '## Görev 1 — Bir\n**Dosya:** `gorevler/ilk.py`\n**Girdi:**\nbozuk\n**Beklenen çıktı:**\n```text\nçıktı\n```\n**Beklenen çıkış kodu:** `2`\n',
    );
    final veri = egitimleriAktar(kaynak.path);
    final gorev = (veri['egitimler'] as List).single['gorevler'][0];
    expect(gorev['kontrol']['girdi'], '');
    expect(gorev['kontrol']['beklenenCikti'], 'çıktı\n');
    expect(gorev['kontrol']['beklenenCikisKodu'], 2);
    expect((veri['uyarilar'] as List).join(), contains('Girdi text bloğu'));
  });

  test('Yinelenen ders kimliği ve bozuk UTF-8 anlaşılır hata verir', () {
    ders();
    yaz('dersler/PY-1/README.md', '# PY-1 — Tekrar');
    expect(() => egitimleriAktar(kaynak.path), throwsFormatException);
    Directory(p.join(kaynak.path, 'dersler/PY-1')).deleteSync(recursive: true);
    File(
      p.join(kaynak.path, 'dersler/PY-01/README.md'),
    ).writeAsBytesSync([255]);
    expect(
      () => egitimleriAktar(kaynak.path),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'mesaj',
          contains('PY-01'),
        ),
      ),
    );
  });

  test('Test satır numarası, binary veri ve sıfır testli boş depo', () {
    expect(testTanimlari('\n\ndef test_gorev_3(): pass\n').single['satir'], 3);
    ders();
    File(
      p.join(kaynak.path, 'dersler/PY-01/veri.bin'),
    ).writeAsBytesSync([255, 0, 1]);
    final egitim = (egitimleriAktar(kaynak.path)['egitimler'] as List).single;
    expect(egitim['kaynakDosyalari']['veri.bin']['kodlama'], 'base64');
    expect(
      base64Decode(egitim['kaynakDosyalari']['veri.bin']['icerik'] as String),
      [255, 0, 1],
    );
    Directory(p.join(kaynak.path, 'dersler/PY-01')).deleteSync(recursive: true);
    expect(egitimleriAktar(kaynak.path)['egitimler'], isEmpty);
  });
  tearDown(() {
    kaynak.deleteSync(recursive: true);
    cikti.deleteSync(recursive: true);
  });

  test(
    'Gerçek görev biçimi, UTF-8, başlangıç ve çok dosyalı bağımlılıklar',
    () {
      ders();
      yaz('dersler/PY-01/cozumler/CEVAPLAR.md', 'GİZLİ CEVAP');
      yaz('dersler/PY-01/cozumler/ilk.py', 'GİZLİ KOD');
      yaz('dersler/PY-01/veri/ornek.txt', 'İstanbul');
      final veri = egitimleriAktar(kaynak.path);
      final egitim = (veri['egitimler'] as List).single;
      expect(egitim['baslik'], 'Türkçe başlık');
      expect(egitim['sira'], 1);
      expect(egitim['gorevler'], hasLength(2));
      final gorev = egitim['gorevler'][0];
      expect(gorev['kontrol']['girdi'], 'Çağla\n');
      expect(gorev['kontrol']['beklenenCikti'], 'Merhaba, Çağla!\n');
      expect(gorev['kontrol']['kullanilmamali'], ['eval', 'exec']);
      expect(
        egitim['kaynakDosyalari']['gorevler/yardimci.py']['icerik'],
        contains('def selam'),
      );
      expect(egitim['kaynakDosyalari']['veri/ornek.txt']['icerik'], 'İstanbul');
      expect(jsonEncode(veri), isNot(contains('GİZLİ')));
      expect(egitim['gorevler'][1]['kontrol'], isNull);
      expect(veri['uyarilar'], hasLength(1));
      final hedef = p.join(cikti.path, 'egitim.json');
      jsonYaz(kaynak.path, hedef, veri);
      expect(jsonDecode(File(hedef).readAsStringSync()), veri);
      expect(egitimleriAktar(kaynak.path), veri);
    },
  );

  test('Test modülü import, fixture ve yardımcılarıyla bütünüyle saklanır', () {
    ders();
    const testKodu = '''import pytest
from gorevler.yardimci import selam
@pytest.fixture
def veri(): return selam()
@pytest.mark.parametrize("x", [1, 2])
def test_gorev_1_normal(veri, x):
    assert veri == x
async def test_gorev_1_sinir(): pass
def test_gorev_9(): pass
''';
    yaz('dersler/PY-01/test_alistirmalar.py', testKodu);
    final veri = egitimleriAktar(kaynak.path);
    final egitim = (veri['egitimler'] as List).single;
    expect(egitim['testKodu'], testKodu);
    expect(egitim['gorevler'][0]['testler'], hasLength(2));
    expect(egitim['testler'], hasLength(3));
    expect((veri['uyarilar'] as List).single, contains('test_gorev_9'));
  });

  test('Python metin ve yorumlarındaki sahte test tanımları sayılmaz', () {
    final kod =
        "# def test_gorev_8(): pass\nmetin = '''\ndef test_gorev_7(): pass\n'''\ndef test_gorev_1(): pass\n";
    expect(testTanimlari(kod).map((t) => t['no']), [1]);
  });

  test('Obsidian callout ve wiki bağlantıları dönüşür; gömme korunur', () {
    final uyarilar = <String>[];
    final sonuc = markdownIsle(
      '> [!note]+ Not\n> açıklama\n[[PY-02/README|Ders]] [[#Bölüm]] ![[resim.png]]',
      uyarilar.add,
    );
    expect(sonuc, contains('> **note: Not**'));
    expect(sonuc, contains('[Ders](<PY-02/README.md>)'));
    expect(sonuc, contains('[#Bölüm](<#Bölüm>)'));
    expect(sonuc, contains('![[resim.png]]'));
    expect(uyarilar, hasLength(1));
  });

  test('Normal Markdown, inline kod, uzun çit ve Python listeleri korunur', () {
    const metin = '''[Normal](README.md)
`[[dokunma]]` ve `` `[[buna da dokunma]]` ``
````python
> [!info]
[[1, 2], [3, 4]]
```
[[dokunma]]
````
    [[girintili]]
''';
    final uyarilar = <String>[];
    expect(markdownIsle(metin, uyarilar.add), metin);
    expect(uyarilar, isEmpty);
  });

  test('Kod bloğundaki görev başlıkları ayrıştırılmaz', () {
    ders(gorevler: '## Görev 1 — Açıkla\n```md\n## Görev 99 — Sahte\n```\n');
    final egitim = (egitimleriAktar(kaynak.path)['egitimler'] as List).single;
    expect(egitim['gorevler'], hasLength(1));
  });

  test('Eksik README ve bozuk başlık ders ve yol içeren hata verir', () {
    ders();
    File(p.join(kaynak.path, 'dersler/PY-01/README.md')).deleteSync();
    expect(
      () => egitimleriAktar(kaynak.path),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'mesaj',
          allOf(contains('PY-01'), contains('README.md')),
        ),
      ),
    );
    yaz('dersler/PY-01/README.md', 'Başlık yok');
    expect(() => egitimleriAktar(kaynak.path), throwsFormatException);
  });

  test('Yinelenen görev ve tehlikeli dosya yolu reddedilir', () {
    ders(gorevler: '## Görev 1 — Bir\n## Görev 1 — İki\n');
    expect(() => egitimleriAktar(kaynak.path), throwsFormatException);
    ders(
      gorevler:
          '## Görev 1 — Bir\n**Dosya:** `gorevler/../../cozumler/cevap.py`\n',
    );
    expect(() => egitimleriAktar(kaynak.path), throwsFormatException);
  });

  test('Eksik başlangıç, çıktı ve test eşleşmesi uyarılır', () {
    ders(gorevler: '## Görev 1 — Bir\n**Dosya:** `gorevler/yok.py`\n');
    yaz('dersler/PY-01/test_alistirmalar.py', 'def test_gorev_2(): pass\n');
    final uyarilar = egitimleriAktar(kaynak.path)['uyarilar'] as List;
    expect(uyarilar, hasLength(4));
    expect(
      uyarilar.every((dynamic u) => (u as String).contains('PY-01')),
      isTrue,
    );
  });

  test('JSON kaynak klasörüne yazılamaz', () {
    ders();
    expect(
      () => jsonYaz(kaynak.path, p.join(kaynak.path, 'yeni', 'veri.json'), {}),
      throwsA(isA<FileSystemException>()),
    );
    expect(Directory(p.join(kaynak.path, 'yeni')).existsSync(), isFalse);
  });

  test('Desteklenmeyen Obsidian ve kapanmayan çit uyarılır', () {
    final uyarilar = <String>[];
    final sonuc = markdownIsle(
      '[[Not#^blok]]\n%%yorum%%\n```python\n',
      uyarilar.add,
    );
    expect(sonuc, contains('[[Not#^blok]]'));
    expect(uyarilar, hasLength(3));
  });
}
