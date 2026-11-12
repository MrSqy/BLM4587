import 'package:egitim_platformu/ekranlar/notebook_goruntuleyici_ekrani.dart';
import 'package:egitim_platformu/modeller/notebook.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

NotebookBelgesi _notebook() => NotebookBelgesi(
  nbformat: 4,
  nbformatMinor: 5,
  metadata: const {},
  hucreler: [
    MarkdownHucresi(
      id: 'md',
      metadata: const {},
      kaynak: '# Giriş',
      ekler: const {},
    ),
    HamHucresi(id: 'ham', metadata: const {}, kaynak: 'gizli', ekler: const {}),
    KodHucresi(
      id: 'kod',
      metadata: const {},
      kaynak: "print('a')",
      calistirmaSayisi: 1,
      ciktilar: const [AkisCiktisi(akisAdi: 'stdout', metin: 'a\n')],
    ),
  ],
);

// Varsayılan test penceresi kısa; ListView ekran dışındaki kartları oluşturmaz.
Future<void> _ac(
  WidgetTester tester, {
  Size boyut = const Size(800, 2400),
}) async {
  tester.view.physicalSize = boyut;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(home: NotebookGoruntuleyiciEkrani(notebook: _notebook())),
  );
  await tester.pumpAndSettle();
}

Future<void> _duzenlemeyiAc(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('notebookDuzenle')));
  await tester.pumpAndSettle();
}

Finder _kaynaklar() => find.byKey(const ValueKey('hucreKaynagi'));

String _kaynak(WidgetTester tester, int sira) =>
    tester.widget<TextField>(_kaynaklar().at(sira)).controller!.text;

void main() {
  testWidgets('duzenle modunda kod hucresi editorde degisir ve ciktisi kalir', (
    tester,
  ) async {
    await _ac(tester);
    expect(_kaynaklar(), findsNothing);

    await _duzenlemeyiAc(tester);
    expect(_kaynaklar(), findsNWidgets(2));
    expect(find.text('a'), findsOneWidget);
    expect(find.text('gizli'), findsNothing);

    await tester.enterText(_kaynaklar().at(1), "print('b')");
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('kaydedilmediUyarisi')), findsOneWidget);

    await _duzenlemeyiAc(tester); // bitir
    expect(find.textContaining("print('b')"), findsOneWidget);
    expect(find.byKey(const ValueKey('kod_2')), findsOneWidget);
  });

  testWidgets('4 bosluk ekle imlecin yerine girinti koyar', (tester) async {
    await _ac(tester);
    await _duzenlemeyiAc(tester);
    final kod = tester.widget<TextField>(_kaynaklar().at(1)).controller!;
    kod.selection = const TextSelection.collapsed(offset: 0);

    await tester.tap(find.byKey(const ValueKey('hucreDortBosluk')));
    await tester.pumpAndSettle();

    expect(_kaynak(tester, 1), "    print('a')");
    expect(kod.selection.baseOffset, 4);
  });

  testWidgets('asagi ve yukari tasima gizli ham hucrenin ustunden atlar', (
    tester,
  ) async {
    await _ac(tester);
    await _duzenlemeyiAc(tester);

    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('hucreYukari')).first)
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('hucreAsagi')).first);
    await tester.pumpAndSettle();
    expect(_kaynak(tester, 0), "print('a')");
    expect(_kaynak(tester, 1), '# Giriş');
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('hucreAsagi')).last)
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('hucreYukari')).last);
    await tester.pumpAndSettle();
    expect(_kaynak(tester, 0), '# Giriş');
  });

  testWidgets('silinen hucre Geri al ile duzenlenmis metniyle doner', (
    tester,
  ) async {
    await _ac(tester);
    await _duzenlemeyiAc(tester);
    await tester.enterText(_kaynaklar().first, '# Yeni başlık');

    await tester.tap(find.byKey(const ValueKey('hucreSil')).first);
    await tester.pumpAndSettle();
    expect(_kaynaklar(), findsOneWidget);
    expect(find.text('Hücre silindi.'), findsOneWidget);

    await tester.tap(find.text('Geri al'));
    await tester.pumpAndSettle();
    expect(_kaynaklar(), findsNWidgets(2));
    expect(_kaynak(tester, 0), '# Yeni başlık');
  });

  testWidgets('hucre ekle dugmesi ve altina ekle menusu yeni hucre acar', (
    tester,
  ) async {
    await _ac(tester);
    await _duzenlemeyiAc(tester);

    await tester.tap(find.byKey(const ValueKey('hucreEkle')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kod hücresi'));
    await tester.pumpAndSettle();
    expect(_kaynaklar(), findsNWidgets(3));
    expect(_kaynak(tester, 2), '');

    await tester.tap(find.byKey(const ValueKey('hucreAltinaEkle')).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Altına markdown hücresi'));
    await tester.pumpAndSettle();
    expect(_kaynaklar(), findsNWidgets(4));
    expect(_kaynak(tester, 1), '');
    expect(find.text('Markdown · 2'), findsOneWidget);
  });

  testWidgets('kaydedilmemis degisiklikle cikista onay ister', (tester) async {
    final gezgin = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: gezgin,
        home: const Scaffold(body: Text('Profil')),
      ),
    );
    gezgin.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => NotebookGoruntuleyiciEkrani(notebook: _notebook()),
      ),
    );
    await tester.pumpAndSettle();
    await _duzenlemeyiAc(tester);
    await tester.tap(find.byKey(const ValueKey('hucreSil')).first);
    await tester.pumpAndSettle();

    gezgin.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Değişiklikler kaybolacak'), findsOneWidget);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(find.text('Profil'), findsNothing);

    gezgin.currentState!.maybePop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Çık'));
    await tester.pumpAndSettle();
    expect(find.text('Profil'), findsOneWidget);
  });

  testWidgets('dar ekranda duzenleme kartlari tasmaz', (tester) async {
    await _ac(tester, boyut: const Size(360, 740));
    await _duzenlemeyiAc(tester);

    expect(tester.takeException(), isNull);
  });
}
