import 'package:egitim_icerik/src/icerik_birlestir.dart';
import 'package:egitim_icerik/src/yukleme_plani.dart';
import 'package:test/test.dart';
import 'yukleme_v2_test.dart' show v2Veri, ders;

void main() {
  final uyarilar = <String>[];
  String birlestir(Map<String, String> md) => dersMetniniBirlestir(
    kod: 'PY-01',
    baslik: 'Python',
    markdown: md,
    uyar: (d, m) => uyarilar.add('$d: $m'),
  );
  setUp(uyarilar.clear);
  test('Tek H1 ve yinelenen başlık bağlantıları', () {
    final m = birlestir({
      'README.md': '# Python\nKonu\n## Ortak\n[x](./ALISTIRMALAR.md#ortak)',
      'ALISTIRMALAR.md': '# Görevler\n## Ortak\n[y](#ortak)\n[z](README.md)',
    });
    expect(RegExp(r'^# ', multiLine: true).allMatches(m), hasLength(1));
    expect(m, contains('## Konu anlatımı\n\nKonu'));
    expect(m, contains('## Alıştırmalar'));
    expect(m, contains('[x](#ortak-1)'));
    expect(m, contains('[y](#ortak-1)'));
    expect(m, contains('[z](#konu-anlat%C4%B1m%C4%B1)'));
    expect(uyarilar, isEmpty);
  });
  test('Kod blokları, satır içi kod ve C# korunur', () {
    const blok = '```md\n# Örnek\n[x](README.md)\n```';
    final m = birlestir({
      'README.md': '# Python\n## C#\n$blok\n`[x](README.md)`',
      'ALISTIRMALAR.md': '# Görevler\n    # Kod\n    [x](README.md)',
    });
    expect(m, contains('### C#'));
    expect(m, contains(blok));
    expect(m, contains('`[x](README.md)`'));
    expect(m, contains('    # Kod\n    [x](README.md)'));
  });
  test('Ek dosya, görsel ve bulunamayan başlık uyarılı korunur', () {
    final m = birlestir({
      'README.md': '# Python\n[x](LAB.md)\n![r](resim.png)\n[x](README.md#yok)',
      'ALISTIRMALAR.md': '# Görevler\nMetin',
    });
    expect(m, contains('[x](LAB.md)'));
    expect(m, contains('![r](resim.png)'));
    expect(m, contains('[x](README.md#yok)'));
    expect(uyarilar, hasLength(3));
  });
  test('Setext ve referans bağlantı', () {
    final m = birlestir({
      'README.md': 'Python\n======\n[g]: ALISTIRMALAR.md',
      'ALISTIRMALAR.md': '# Görevler\nMetin',
    });
    expect(m, isNot(contains('======')));
    expect(m, contains('[g]: #al%C4%B1%C5%9Ft%C4%B1rmalar'));
  });
  test('Boş kaynak reddedilir', () {
    expect(
      () => birlestir({'README.md': '# Python', 'ALISTIRMALAR.md': ''}),
      throwsFormatException,
    );
  });
  test('V2 sadece gerçekten birleşen kaynakları korunmuş sayar', () {
    final v = v2Veri();
    final d = ders(v);
    final md = {
      'README.md': '# Python\nKonu',
      'ALISTIRMALAR.md': '# Görevler\nGörev',
      'LAB.md': '# Lab',
      'TROUBLESHOOTING.md': '# Sorun',
    };
    d['markdownDosyalari'] = md;
    d['icerikMarkdown'] = dersMetniniBirlestir(
      kod: 'PY-01',
      baslik: d['baslik'],
      markdown: md,
      uyar: (_, _) {},
    );
    final k = yuklemePlani(v, {'PY-01'}).kayiplar.join('\n');
    expect(k, contains('LAB.md, TROUBLESHOOTING.md'));
    expect(k, isNot(contains('README.md')));
    expect(k, isNot(contains('ALISTIRMALAR.md')));
    d['icerikMarkdown'] = md['ALISTIRMALAR.md'];
    expect(
      yuklemePlani(v, {'PY-01'}).kayiplar.join('\n'),
      contains('README.md'),
    );
  });
}
