import 'dart:convert';
import 'dart:io';

import 'package:egitim_platformu/modeller/notebook.dart';
import 'package:flutter_test/flutter_test.dart';

String _fixtureMetni() {
  return File('test/fixtures/ornek_notebook.ipynb').readAsStringSync();
}

void main() {
  test('nbformat 4 notebook temel alanlariyla okunur', () {
    final notebook = NotebookBelgesi.fromJsonString(_fixtureMetni());

    expect(notebook.nbformat, 4);
    expect(notebook.nbformatMinor, 5);
    expect(notebook.hucreler, hasLength(3));
    expect(notebook.hucreler[0], isA<MarkdownHucresi>());
    expect(notebook.hucreler[1], isA<KodHucresi>());
    expect(notebook.hucreler[2], isA<HamHucresi>());
  });

  test('source metin veya metin listesi olabilir', () {
    final notebook = NotebookBelgesi.fromJsonString(_fixtureMetni());

    expect(
      notebook.hucreler[0].kaynak,
      '# Örnek notebook\nBu hücre liste biçiminde saklanır.',
    );
    expect(notebook.hucreler[1].kaynak, "print('merhaba')");
    expect(notebook.hucreler[2].kaynak, 'ham\niçerik');
  });

  test('notebook JSON turunda metadata korunur', () {
    final ilkNotebook = NotebookBelgesi.fromJsonString(_fixtureMetni());
    final ikinciNotebook = NotebookBelgesi.fromJsonString(
      ilkNotebook.toJsonString(),
    );
    final json = jsonDecode(ilkNotebook.toJsonString()) as Map<String, dynamic>;

    expect(ikinciNotebook.metadata, ilkNotebook.metadata);
    expect(ikinciNotebook.hucreler[0].metadata, {'etiket': 'giris'});
    expect(ikinciNotebook.hucreler[0].id, 'giris-hucresi');
    expect(json['nbformat_minor'], 5);
  });

  test('markdown ve raw ekleri JSON turunda korunur', () {
    final ilkNotebook = NotebookBelgesi.fromJsonString(_fixtureMetni());
    final ikinciNotebook = NotebookBelgesi.fromJsonString(
      ilkNotebook.toJsonString(),
    );

    expect((ikinciNotebook.hucreler[0] as MarkdownHucresi).ekler, {
      'sekil.png': {'image/png': 'aW1hZ2U='},
    });
    expect((ikinciNotebook.hucreler[2] as HamHucresi).ekler, {
      'not.txt': {'text/plain': 'ham ek'},
    });
  });

  test('stream ciktilari metin veya metin listesiyle okunur', () {
    final notebook = NotebookBelgesi.fromJsonString(_fixtureMetni());
    final kodHucresi = notebook.hucreler[1] as KodHucresi;

    expect(kodHucresi.ciktilar, hasLength(5));
    expect(kodHucresi.ciktilar[0], isA<AkisCiktisi>());
    expect((kodHucresi.ciktilar[0] as AkisCiktisi).metin, 'satır 1\nsatır 2\n');
    expect((kodHucresi.ciktilar[0] as AkisCiktisi).akisAdi, 'stdout');
    expect((kodHucresi.ciktilar[1] as AkisCiktisi).metin, 'uyarı\n');
    expect((kodHucresi.ciktilar[1] as AkisCiktisi).akisAdi, 'stderr');
  });

  test('zengin sonuc ve hata ciktilari alanlarini korur', () {
    final notebook = NotebookBelgesi.fromJsonString(_fixtureMetni());
    final kodHucresi = notebook.hucreler[1] as KodHucresi;
    final gosterim = kodHucresi.ciktilar[2] as GosterimCiktisi;
    final sonuc = kodHucresi.ciktilar[3] as CalistirmaSonucu;
    final hata = kodHucresi.ciktilar[4] as HataCiktisi;

    expect(gosterim.veri['image/png'], 'aW1hZ2U=');
    expect(gosterim.metadata['image/png'], {'height': 480, 'width': 640});
    expect(sonuc.calistirmaSayisi, 7);
    expect(sonuc.veri['application/json'], {'deger': 42});
    expect(hata.hataAdi, 'ValueError');
    expect(hata.hataDegeri, 'hatalı değer');
    expect(hata.iz, hasLength(2));
  });

  test('tum cikti turleri JSON turunda korunur', () {
    final ilkNotebook = NotebookBelgesi.fromJsonString(_fixtureMetni());
    final ikinciNotebook = NotebookBelgesi.fromJsonString(
      ilkNotebook.toJsonString(),
    );
    final kodHucresi = ikinciNotebook.hucreler[1] as KodHucresi;

    expect(kodHucresi.calistirmaSayisi, 7);
    expect(kodHucresi.ciktilar.map((cikti) => cikti.runtimeType), [
      AkisCiktisi,
      AkisCiktisi,
      GosterimCiktisi,
      CalistirmaSonucu,
      HataCiktisi,
    ]);
    expect(
      kodHucresi.ciktilar.map((cikti) => cikti.toJson()).toList(),
      (ilkNotebook.hucreler[1] as KodHucresi).ciktilar
          .map((cikti) => cikti.toJson())
          .toList(),
    );
  });

  test('null execute_result execution_count JSON turunda korunur', () {
    final notebook = NotebookBelgesi.fromJson(
      _tekHucreliNotebook(
        _kodHucresi(
          outputs: [
            {
              'output_type': 'execute_result',
              'execution_count': null,
              'data': <String, dynamic>{'text/plain': 'sonuc'},
              'metadata': <String, dynamic>{},
            },
          ],
        ),
      ),
    );

    final sonuc =
        (notebook.hucreler.single as KodHucresi).ciktilar.single
            as CalistirmaSonucu;
    expect(sonuc.calistirmaSayisi, isNull);
    expect(sonuc.toJson()['execution_count'], isNull);
  });

  test('eksik code execution_count alan yoluyla reddedilir', () {
    final hucre = _kodHucresi()..remove('execution_count');

    expect(
      () => NotebookBelgesi.fromJson(_tekHucreliNotebook(hucre)),
      throwsA(
        isA<FormatException>().having(
          (hata) => hata.message,
          'message',
          contains('cells[0].execution_count'),
        ),
      ),
    );
  });

  test('eksik execute_result execution_count alan yoluyla reddedilir', () {
    expect(
      () => NotebookBelgesi.fromJson(
        _tekHucreliNotebook(
          _kodHucresi(
            outputs: [
              {
                'output_type': 'execute_result',
                'data': <String, dynamic>{},
                'metadata': <String, dynamic>{},
              },
            ],
          ),
        ),
      ),
      throwsA(
        isA<FormatException>().having(
          (hata) => hata.message,
          'message',
          contains('cells[0].outputs[0].execution_count'),
        ),
      ),
    );
  });

  test('nbformat 4.5 hucre kimligini zorunlu tutar', () {
    expect(
      () => NotebookBelgesi.fromJson(
        _tekHucreliNotebook(_kodHucresi()..remove('id')),
      ),
      throwsA(
        isA<FormatException>().having(
          (hata) => hata.message,
          'message',
          contains('cells[0].id'),
        ),
      ),
    );
    expect(
      () => NotebookBelgesi.fromJson(
        _tekHucreliNotebook(_kodHucresi()..['id'] = null),
      ),
      throwsA(
        isA<FormatException>().having(
          (hata) => hata.message,
          'message',
          contains('cells[0].id'),
        ),
      ),
    );
  });

  test('nbformat 4.4 kimliksiz hucreyi kabul eder', () {
    final json = _tekHucreliNotebook(_kodHucresi()..remove('id'));
    json['nbformat_minor'] = 4;

    final notebook = NotebookBelgesi.fromJson(json);

    expect(notebook.hucreler.single.id, isNull);
  });

  test('eksik cells alani aciklayici FormatException uretir', () {
    expect(
      () => NotebookBelgesi.fromJson({
        'metadata': <String, dynamic>{},
        'nbformat': 4,
        'nbformat_minor': 5,
      }),
      throwsA(
        isA<FormatException>().having(
          (hata) => hata.message,
          'message',
          contains('cells'),
        ),
      ),
    );
  });

  test('desteklenmeyen cell_type alan yoluyla reddedilir', () {
    expect(
      () => NotebookBelgesi.fromJson(
        _tekHucreliNotebook({
          'cell_type': 'bilinmeyen',
          'metadata': <String, dynamic>{},
          'source': '',
        }),
      ),
      throwsA(
        isA<FormatException>().having(
          (hata) => hata.message,
          'message',
          contains('cells[0].cell_type'),
        ),
      ),
    );
  });

  test('desteklenmeyen output_type alan yoluyla reddedilir', () {
    expect(
      () => NotebookBelgesi.fromJson(
        _tekHucreliNotebook(
          _kodHucresi(
            outputs: [
              {'output_type': 'bilinmeyen'},
            ],
          ),
        ),
      ),
      throwsA(
        isA<FormatException>().having(
          (hata) => hata.message,
          'message',
          contains('cells[0].outputs[0].output_type'),
        ),
      ),
    );
  });

  test('yanlis execution_count tipi alan yoluyla reddedilir', () {
    expect(
      () => NotebookBelgesi.fromJson(
        _tekHucreliNotebook(_kodHucresi(executionCount: 'yedi')),
      ),
      throwsA(
        isA<FormatException>().having(
          (hata) => hata.message,
          'message',
          contains('cells[0].execution_count'),
        ),
      ),
    );
  });

  test('metin veya liste olmayan source alan yoluyla reddedilir', () {
    expect(
      () => NotebookBelgesi.fromJson(
        _tekHucreliNotebook({
          'cell_type': 'markdown',
          'id': 'markdown-hucresi',
          'metadata': <String, dynamic>{},
          'source': 42,
        }),
      ),
      throwsA(
        isA<FormatException>().having(
          (hata) => hata.message,
          'message',
          contains('cells[0].source'),
        ),
      ),
    );
  });
}

Map<String, dynamic> _tekHucreliNotebook(Map<String, dynamic> hucre) {
  return {
    'cells': [hucre],
    'metadata': <String, dynamic>{},
    'nbformat': 4,
    'nbformat_minor': 5,
  };
}

Map<String, dynamic> _kodHucresi({
  dynamic executionCount,
  List<Map<String, dynamic>> outputs = const [],
}) {
  return {
    'cell_type': 'code',
    'execution_count': executionCount,
    'id': 'kod-hucresi',
    'metadata': <String, dynamic>{},
    'outputs': outputs,
    'source': '',
  };
}
