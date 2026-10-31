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
}
