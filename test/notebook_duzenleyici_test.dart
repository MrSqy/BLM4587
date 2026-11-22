import 'dart:math';

import 'package:egitim_platformu/modeller/notebook.dart';
import 'package:egitim_platformu/modeller/notebook_duzenleyici.dart';
import 'package:flutter_test/flutter_test.dart';

NotebookBelgesi _belge({int minor = 5}) => NotebookBelgesi(
  nbformat: 4,
  nbformatMinor: minor,
  metadata: const {'kernelspec': 'python3'},
  hucreler: [
    MarkdownHucresi(
      id: minor >= 5 ? 'md' : null,
      metadata: const {},
      kaynak: '# Başlık',
      ekler: const {},
    ),
    KodHucresi(
      id: minor >= 5 ? 'kod' : null,
      metadata: const {'tags': 'ornek'},
      kaynak: 'print(1)',
      calistirmaSayisi: 3,
      ciktilar: const [AkisCiktisi(akisAdi: 'stdout', metin: '1\n')],
    ),
  ],
);

/// Önce verilen sayıları, bitince hep 1'i döndürür.
class _SiraliRastgele implements Random {
  final List<int> sayilar;
  var _i = 0;
  _SiraliRastgele(this.sayilar);

  @override
  int nextInt(int max) => _i < sayilar.length ? sayilar[_i++] : 1;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

void main() {
  test(
    'bos kod ve markdown hucresi ekler, 4.5 notebookta benzersiz kimlik verir',
    () {
      final d = NotebookDuzenleyici(_belge());

      expect(d.ekle(1, YeniHucreTuru.kod), 1);
      d.ekle(3, YeniHucreTuru.markdown);

      final kod = d.hucreler[1] as KodHucresi;
      expect(kod.kaynak, '');
      expect(kod.calistirmaSayisi, isNull);
      expect(kod.ciktilar, isEmpty);
      expect(kod.id, matches(RegExp(r'^[0-9a-f]{8}$')));
      expect(d.hucreler[3], isA<MarkdownHucresi>());
      expect(d.hucreler.map((h) => h.id).toSet(), hasLength(4));
      expect(d.degisti, isTrue);
    },
  );

  test('yeni kimlik var olanla cakisirsa yenisi uretilir', () {
    final belge = NotebookBelgesi(
      nbformat: 4,
      nbformatMinor: 5,
      metadata: const {},
      hucreler: [
        KodHucresi(
          id: '00000000',
          metadata: const {},
          kaynak: '',
          calistirmaSayisi: null,
          ciktilar: const [],
        ),
      ],
    );
    final d = NotebookDuzenleyici(
      belge,
      rastgele: _SiraliRastgele(List.filled(8, 0)),
    );

    d.ekle(1, YeniHucreTuru.kod);

    expect(d.hucreler[1].id, '11111111');
  });

  test('4.5 oncesi notebookta yeni hucreye kimlik yazilmaz', () {
    final d = NotebookDuzenleyici(_belge(minor: 4));

    d.ekle(0, YeniHucreTuru.markdown);

    expect(d.hucreler.first.id, isNull);
    expect(d.belge.toJson()['cells'][0].containsKey('id'), isFalse);
  });

  test('silinen hucre geri alininca ayni yere ayni anahtarla doner', () {
    final d = NotebookDuzenleyici(_belge());
    final anahtar = d.anahtar(0);

    final silinen = d.sil(0);
    expect(d.uzunluk, 1);
    expect(d.anahtarIndeksi(anahtar), -1);

    d.geriAl(silinen);
    d.geriAl(silinen); // ikinci kez eklenmez
    expect(d.uzunluk, 2);
    expect(d.hucreler.first.kaynak, '# Başlık');
    expect(d.anahtarIndeksi(anahtar), 0);
  });

  test('tasi hucreyi verilen son konuma koyar, anahtar hucreyle gider', () {
    final d = NotebookDuzenleyici(_belge());
    d.ekle(2, YeniHucreTuru.markdown);
    final kodAnahtari = d.anahtar(1);

    d.tasi(0, 2);
    expect(d.hucreler.map((h) => h.runtimeType), [
      KodHucresi,
      MarkdownHucresi,
      MarkdownHucresi,
    ]);
    expect(d.hucreler.last.kaynak, '# Başlık');
    expect(d.anahtarIndeksi(kodAnahtari), 0);

    d.tasi(2, 0);
    expect(d.hucreler.first.kaynak, '# Başlık');
    expect(() => d.tasi(0, 3), throwsRangeError);
    expect(() => d.sil(5), throwsRangeError);
    expect(() => d.ekle(-1, YeniHucreTuru.kod), throwsRangeError);
  });

  test('kaynak degisince kimlik, metadata ve kayitli ciktilar korunur', () {
    final d = NotebookDuzenleyici(_belge());

    d.kaynakGuncelle(1, 'print(2)');

    final kod = d.hucreler[1] as KodHucresi;
    expect(kod.kaynak, 'print(2)');
    expect(kod.id, 'kod');
    expect(kod.metadata, {'tags': 'ornek'});
    expect(kod.calistirmaSayisi, 3);
    expect(kod.ciktilar, hasLength(1));
  });

  test('ayni metin degisiklik sayilmaz, ozgun belge degismez', () {
    final ozgun = _belge();
    final d = NotebookDuzenleyici(ozgun);
    var bildirim = 0;
    d.addListener(() => bildirim++);

    d.kaynakGuncelle(0, '# Başlık');
    expect(d.degisti, isFalse);
    expect(bildirim, 0);

    d.sil(0);
    expect(ozgun.hucreler, hasLength(2));
    expect(bildirim, 1);
  });

  test('duzenlenmis belge gecerli notebook JSON olarak geri okunur', () {
    final d = NotebookDuzenleyici(_belge());
    d.ekle(0, YeniHucreTuru.kod);
    d.kaynakGuncelle(0, 'x = 1\n');
    d.tasi(0, 2);

    final okunan = NotebookBelgesi.fromJsonString(d.belge.toJsonString());

    expect(okunan.metadata, {'kernelspec': 'python3'});
    expect(okunan.hucreler.map((h) => h.kaynak), [
      '# Başlık',
      'print(1)',
      'x = 1\n',
    ]);
  });
}
