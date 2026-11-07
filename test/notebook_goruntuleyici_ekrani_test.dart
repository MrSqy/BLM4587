import 'dart:io';

import 'package:egitim_platformu/ekranlar/notebook_ciktilari.dart';
import 'package:egitim_platformu/ekranlar/notebook_goruntuleyici_ekrani.dart';
import 'package:egitim_platformu/modeller/notebook.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

NotebookBelgesi _ornekNotebook() {
  return NotebookBelgesi(
    nbformat: 4,
    nbformatMinor: 5,
    metadata: const {},
    hucreler: [
      MarkdownHucresi(
        id: 'markdown',
        metadata: const {},
        kaynak: '# Başlık\n\nBu **kalın** bir açıklamadır.',
        ekler: const {},
      ),
      KodHucresi(
        id: 'kod',
        metadata: const {},
        kaynak: "print('merhaba')",
        calistirmaSayisi: 3,
        ciktilar: const [],
      ),
      HamHucresi(
        id: 'ham',
        metadata: const {},
        kaynak: 'gösterilmemesi gereken ham hücre',
        ekler: const {},
      ),
    ],
  );
}

Future<void> _ekraniAc(WidgetTester tester, {NotebookBelgesi? notebook}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: NotebookGoruntuleyiciEkrani(
        baslik: 'PY-01 Notebook',
        notebook: notebook ?? _ornekNotebook(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('markdown ve kod hucrelerini sirasiyla salt okunur gosterir', (
    tester,
  ) async {
    await _ekraniAc(tester);

    expect(find.text('PY-01 Notebook'), findsOneWidget);
    expect(find.byKey(const ValueKey('markdown_0')), findsOneWidget);
    expect(find.text('Başlık'), findsOneWidget);
    expect(find.textContaining('kalın'), findsWidgets);
    expect(find.byKey(const ValueKey('kod_1')), findsOneWidget);
    expect(find.text("print('merhaba')"), findsOneWidget);
    expect(find.text('Çalıştırma [3]'), findsOneWidget);
    expect(find.textContaining('ham hücre'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    for (final widget in tester.widgetList<EditableText>(
      find.byType(EditableText),
    )) {
      expect(widget.readOnly, isTrue);
    }
  });

  testWidgets('desteklenen hucre yoksa aciklayici bos durum gosterir', (
    tester,
  ) async {
    final notebook = NotebookBelgesi(
      nbformat: 4,
      nbformatMinor: 5,
      metadata: const {},
      hucreler: [
        HamHucresi(
          id: 'ham',
          metadata: const {},
          kaynak: 'ham',
          ekler: const {},
        ),
      ],
    );

    await _ekraniAc(tester, notebook: notebook);

    expect(
      find.text('Bu notebookta gösterilebilen markdown veya kod hücresi yok.'),
      findsOneWidget,
    );
  });

  testWidgets('uzun kod dar ekranda tasma olusturmaz', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final notebook = NotebookBelgesi(
      nbformat: 4,
      nbformatMinor: 5,
      metadata: const {},
      hucreler: [
        KodHucresi(
          id: 'uzun-kod',
          metadata: const {},
          kaynak: 'sonuc = ${List.filled(30, 'cok_uzun_degisken').join(' + ')}',
          calistirmaSayisi: null,
          ciktilar: const [],
        ),
      ],
    );

    await _ekraniAc(tester, notebook: notebook);

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsWidgets);
  });

  testWidgets('markdown attachment gorselini bellekten gosterir', (
    tester,
  ) async {
    final notebook = NotebookBelgesi(
      nbformat: 4,
      nbformatMinor: 5,
      metadata: const {},
      hucreler: [
        MarkdownHucresi(
          id: 'ekli-gorsel',
          metadata: const {},
          kaynak: '![örnek](attachment:piksel.png)',
          ekler: const {
            'piksel.png': {
              'image/png':
                  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
            },
          },
        ),
      ],
    );

    await _ekraniAc(tester, notebook: notebook);

    expect(find.byKey(const ValueKey('attachment_piksel.png')), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('kayitli metin ciktilarini, stderr hata renginde gosterir', (
    tester,
  ) async {
    await _ekraniAc(
      tester,
      notebook: _ciktiliNotebook([
        const AkisCiktisi(akisAdi: 'stdout', metin: 'Merhaba\n'),
        const AkisCiktisi(akisAdi: 'stderr', metin: 'uyarı\n'),
        CalistirmaSonucu(
          calistirmaSayisi: 1,
          veri: const {
            'text/plain': ['4', '2'],
          },
          metadata: const {},
        ),
      ]),
    );

    expect(find.text('Merhaba'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    final stderr = tester.widget<SelectableText>(_secilebilir('uyarı'));
    final tema = Theme.of(tester.element(find.text('uyarı')));
    expect(stderr.style?.color, tema.colorScheme.error);
  });

  testWidgets('pandas HTML ciktisini tablo olarak gosterir', (tester) async {
    await _ekraniAc(
      tester,
      notebook: _ciktiliNotebook([
        CalistirmaSonucu(
          calistirmaSayisi: 2,
          veri: const {
            'text/html':
                '<table><thead><tr><th></th><th>ders</th><th>gorev</th></tr></thead>'
                '<tbody><tr><th>0</th><td>PY-01</td><td>7</td></tr>'
                '<tr><th>1</th><td>A &amp; B</td></tr></tbody></table>',
            'text/plain': 'duz metin tablo',
          },
          metadata: const {},
        ),
      ]),
    );

    final tablo = tester.widget<DataTable>(find.byType(DataTable));
    expect(tablo.columns, hasLength(3));
    expect(tablo.rows, hasLength(2));
    expect(find.text('ders'), findsOneWidget);
    expect(find.text('PY-01'), findsOneWidget);
    expect(find.text('A & B'), findsOneWidget);
    expect(find.text('duz metin tablo'), findsNothing);
  });

  testWidgets('png ciktisini gorsel olarak, bozuk gorseli mesajla gosterir', (
    tester,
  ) async {
    await _ekraniAc(
      tester,
      notebook: _ciktiliNotebook([
        GosterimCiktisi(
          veri: const {
            'image/png':
                'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=\n',
            'text/plain': '<Figure>',
          },
          metadata: const {},
        ),
        GosterimCiktisi(
          veri: const {'image/png': '%%%bozuk%%%'},
          metadata: const {},
        ),
      ]),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('<Figure>'), findsNothing);
    expect(find.text('Görsel çıktı görüntülenemedi.'), findsOneWidget);
  });

  testWidgets('hata ciktisini renk kodlari temizlenmis gosterir', (
    tester,
  ) async {
    await _ekraniAc(
      tester,
      notebook: _ciktiliNotebook([
        HataCiktisi(
          hataAdi: 'ZeroDivisionError',
          hataDegeri: 'division by zero',
          iz: const ['\u001b[31mZeroDivisionError\u001b[39m: division by zero'],
        ),
      ]),
    );

    final metin = tester
        .widget<SelectableText>(_secilebilir('ZeroDivisionError'))
        .data!;
    expect(metin, startsWith('ZeroDivisionError: division by zero'));
    expect(metin, isNot(contains('\u001b')));
  });

  test('html tablo okuyucu tablo yoksa null doner', () {
    expect(htmlTablosunuOku('<p>tablo yok</p>'), isNull);
    expect(htmlTablosunuOku('<TABLE><TR><TD>x&lt;1</TD></TR></TABLE>'), [
      ['x<1'],
    ]);
  });

  testWidgets('ornek notebook butun ciktilariyla dar ekranda acilir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final notebook = NotebookBelgesi.fromJsonString(
      File('assets/ornek_notebook.ipynb').readAsStringSync(),
    );

    await tester.pumpWidget(
      MaterialApp(home: OrnekNotebookEkrani(yukleyici: () async => notebook)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(AppBar, 'Örnek notebook'), findsOneWidget);
    expect(find.text('Merhaba, notebook!'), findsOneWidget);
    final liste = find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byType(DataTable),
      200,
      scrollable: liste,
    );
    expect(find.text('PY-02'), findsOneWidget);
    await tester.scrollUntilVisible(
      _secilebilir('ZeroDivisionError'),
      200,
      scrollable: liste,
    );
    expect(tester.takeException(), isNull);
  });
}

NotebookBelgesi _ciktiliNotebook(List<NotebookCiktisi> ciktilar) {
  return NotebookBelgesi(
    nbformat: 4,
    nbformatMinor: 5,
    metadata: const {},
    hucreler: [
      KodHucresi(
        id: 'ciktili',
        metadata: const {},
        kaynak: 'hesapla()',
        calistirmaSayisi: 1,
        ciktilar: ciktilar,
      ),
    ],
  );
}

Finder _secilebilir(String metin) => find.byWidgetPredicate(
  (w) => w is SelectableText && (w.data ?? '').contains(metin),
);
