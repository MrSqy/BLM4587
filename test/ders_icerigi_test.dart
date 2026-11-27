import 'dart:io';

import 'package:egitim_platformu/bilesenler/ders_icerigi.dart';
import 'package:egitim_platformu/ekranlar/ders_ekrani.dart';
import 'package:egitim_platformu/modeller/egitim.dart';
import 'package:egitim_platformu/modeller/gorev.dart';
import 'package:egitim_platformu/servisler/oturum_servisi.dart';
import 'package:egitim_platformu/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ders_akisi_test.dart' show DersServisi, acik;
import 'destek/oturum_destegi.dart';

Finder metin(String text) => find.byWidgetPredicate(
  (w) =>
      (w is SelectableText && (w.textSpan?.toPlainText() ?? w.data) == text) ||
      (w is Text && (w.textSpan?.toPlainText() ?? w.data) == text),
);

/// Seçilebilir metne jesti doğrudan çağırmadan gerçek ekran dokunuşu gönderir.
Future<void> tikla(WidgetTester tester, String etiket) async {
  for (final element in find.byType(SelectableText).evaluate()) {
    final widget = element.widget as SelectableText;
    final text = widget.textSpan?.toPlainText() ?? widget.data ?? '';
    final index = text.indexOf(etiket);
    if (index < 0) continue;
    final edit = find.descendant(
      of: find.byWidget(widget),
      matching: find.byType(EditableText),
    );
    final render = tester.state<EditableTextState>(edit.first).renderEditable;
    final boxes = render.getBoxesForSelection(
      TextSelection(baseOffset: index, extentOffset: index + etiket.length),
    );
    for (final box in boxes) {
      final nokta = render.localToGlobal(box.toRect().center);
      final boyut = tester.view.physicalSize / tester.view.devicePixelRatio;
      if (nokta.dx >= 0 &&
          nokta.dx < boyut.width &&
          nokta.dy >= 0 &&
          nokta.dy < boyut.height) {
        await tester.tapAt(nokta);
        return;
      }
    }
  }
  fail('Görünür bağlantı bulunamadı: $etiket');
}

double yaziBoyutu(TextSpan span) {
  var enBuyuk = span.style?.fontSize ?? 0;
  for (final child in span.children ?? <InlineSpan>[]) {
    if (child is TextSpan) {
      final boyut = yaziBoyutu(child);
      if (boyut > enBuyuk) enBuyuk = boyut;
    }
  }
  return enBuyuk;
}

Future<void> goster(
  WidgetTester tester,
  String data, {
  ScrollController? controller,
  ThemeData? tema,
  double olcek = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: tema ?? acikTema,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(olcek)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          child: DersIcerigi(metin: data),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String araMetin() => List.generate(
  28,
  (i) => 'Paragraf $i. Ders anlatımı ve örnekler.\n\n',
).join();

void main() {
  testWidgets('Başlık/paragraf/liste, kalın ve satır içi kod biçimlenir', (
    tester,
  ) async {
    await goster(
      tester,
      '# Başlık\n\nParagraf **kalın** ve `kod`.\n\n- Birinci\n- İkinci\n\n1. Sıralı\n2. Son',
    );
    expect(metin('Başlık'), findsOneWidget);
    expect(metin('Paragraf kalın ve kod.'), findsOneWidget);
    expect(metin('Birinci'), findsOneWidget);
    expect(metin('İkinci'), findsOneWidget);
    expect(metin('Sıralı'), findsOneWidget);
    final baslik = tester.widget<SelectableText>(metin('Başlık'));
    final paragraf = tester.widget<SelectableText>(
      metin('Paragraf kalın ve kod.'),
    );
    expect(
      yaziBoyutu(baslik.textSpan!),
      greaterThan(yaziBoyutu(paragraf.textSpan!)),
    );
    final stiller = <TextStyle>[];
    void tara(InlineSpan span) {
      if (span.style != null) stiller.add(span.style!);
      if (span is TextSpan) span.children?.forEach(tara);
    }

    tara(paragraf.textSpan!);
    expect(stiller.any((s) => s.fontWeight == FontWeight.bold), isTrue);
    expect(stiller.any((s) => s.fontFamily == 'monospace'), isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final tema in [acikTema, koyuTema]) {
    testWidgets(
      '280px / büyük yazı: yalnız kod yatay kayar, boşluklar korunur ${tema.brightness}',
      (tester) async {
        tester.view.physicalSize = const Size(280, 600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final dis = ScrollController();
        addTearDown(dis.dispose);
        final kod =
            'if True:\n    print("${'uzun_satir_' * 35}")\n\n    print("<bitti>")\n';
        await goster(
          tester,
          '## Kod örneği\n\n```python\n$kod```\n\nNormal paragraf.',
          controller: dis,
          tema: tema,
          olcek: 1.7,
        );
        expect(metin(kod), findsOneWidget);
        expect(
          tester.renderObject<RenderParagraph>(metin(kod)).textScaler.scale(1),
          1.7,
        );
        final yatay = find.byWidgetPredicate(
          (w) =>
              w is SingleChildScrollView &&
              w.scrollDirection == Axis.horizontal,
        );
        expect(yatay, findsOneWidget);
        final scroll = tester.state<ScrollableState>(
          find.descendant(of: yatay, matching: find.byType(Scrollable)).first,
        );
        expect(scroll.position.maxScrollExtent, greaterThan(100));
        expect(tester.getSize(yatay).width, lessThanOrEqualTo(248));
        final once = dis.offset;
        await tester.drag(yatay, const Offset(-150, 0));
        await tester.pumpAndSettle();
        expect(scroll.position.pixels, greaterThan(0));
        expect(dis.offset, once);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Türkçe yüzde kodlamalı bağlantı ilgili başlığa gerçekten kaydırır',
    (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await goster(
        tester,
        '[Bölüme git](#al%C4%B1%C5%9Ft%C4%B1rmalar)\n\n${araMetin()}\n## Alıştırmalar\n\nHedef bölüm.\n\n${araMetin()}',
        controller: scroll,
      );
      expect(tester.getTopLeft(metin('Alıştırmalar')).dy, greaterThan(600));
      await tikla(tester, 'Bölüme git');
      await tester.pumpAndSettle();
      expect(scroll.offset, greaterThan(500));
      expect(
        tester.getTopLeft(metin('Alıştırmalar')).dy,
        inInclusiveRange(0, 100),
      );
    },
  );

  testWidgets(
    'Kod içindeki sahte başlık sayılmaz; yinelenen başlığa -1 ile gidilir',
    (tester) async {
      await goster(
        tester,
        '[İkinciye git](#tekrar-1)\n\n# Tekrar\n\n```text\n# Tekrar\n```\n\n${araMetin()}\n## Tekrar\n\n${araMetin()}',
      );
      await tikla(tester, 'İkinciye git');
      await tester.pumpAndSettle();
      expect(metin('Tekrar'), findsNWidgets(2));
      expect(
        tester.getTopLeft(metin('Tekrar').last).dy,
        inInclusiveRange(0, 100),
      );
    },
  );

  testWidgets(
    'Setext ve kodlanmamış Türkçe başlık hedefi; başlık içi vurgu korunur',
    (tester) async {
      await goster(
        tester,
        '[Git](#Çıkış)\n\n${araMetin()}\nÇıkış\n-----\n\n### **Kalın** ve `kod`\n\n${araMetin()}',
      );
      await tikla(tester, 'Git');
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(metin('Çıkış')).dy, inInclusiveRange(0, 100));
      expect(metin('Kalın ve kod'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Olmayan hedef ve göreli dosya sessizce yok sayılmaz', (
    tester,
  ) async {
    await goster(tester, '[Eksik](#yok)\n\n[Laboratuvar](LAB.md)');
    await tikla(tester, 'Eksik');
    await tester.pumpAndSettle();
    expect(
      find.text('Bu derste bağlantının hedef bölümü bulunamadı.'),
      findsOneWidget,
    );
    ScaffoldMessenger.of(
      tester.element(find.byType(DersIcerigi)),
    ).removeCurrentSnackBar();
    await tester.pumpAndSettle();
    await tikla(tester, 'Laboratuvar');
    await tester.pumpAndSettle();
    expect(
      find.text('Bu dosya veya bağlantı uygulamada açılamıyor.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dış bağlantı URL olarak görünür; yerel bölüm sanılmaz', (
    tester,
  ) async {
    await goster(tester, '[Belge](https://example.test/ders#konu)');
    await tikla(tester, 'Belge');
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Dış bağlantı'), findsOneWidget);
    expect(find.text('https://example.test/ders#konu'), findsOneWidget);
    expect(find.text('Bağlantıyı kopyala'), findsOneWidget);
  });

  for (final (dosya, etiket) in [
    ('python.md', 'Görevler'),
    ('teknik_mulakat.md', 'Alıştırmalara geç'),
  ]) {
    testWidgets('Gerçek aktarım örneği: $dosya başlık bağlantısı', (
      tester,
    ) async {
      // Önceki PY-01 ve TM-DEMO-00 aktarım JSON'undan kısaltılmış metinler.
      // Test canlı API, Python veya kişisel mutlak yol kullanmaz.
      final data = File('test/fixtures/ders_icerigi/$dosya').readAsStringSync();
      await goster(tester, data);
      await tikla(tester, etiket);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(metin('Alıştırmalar')).dy,
        inInclusiveRange(0, 100),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('İçerik değişince eski başlık hedefi kalmaz', (tester) async {
    await goster(tester, '# Eski\n\n[Git](#eski)');
    await goster(tester, '# Yeni\n\n[Git](#eski)');
    await tikla(tester, 'Git');
    await tester.pumpAndSettle();
    expect(
      find.text('Bu derste bağlantının hedef bölümü bulunamadı.'),
      findsOneWidget,
    );
  });

  testWidgets('Kod kopyalama girintileri ve son satır sonunu korur', (
    tester,
  ) async {
    const kod = 'if True:\n    print("Türkçe")\n\n';
    String? kopyalanan;
    final mesajci =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    mesajci.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        kopyalanan = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(
      () => mesajci.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await goster(tester, '```python\n$kod```');
    await tester.tap(find.byTooltip('Kodu kopyala'));
    await tester.pump();
    expect(kopyalanan, kod);
  });

  testWidgets('Bozuk UTF-8 başlık bağlantısı hata fırlatmaz', (tester) async {
    await goster(tester, '[Bozuk](#%FF)');
    await tikla(tester, 'Bozuk');
    await tester.pumpAndSettle();
    expect(
      find.text('Bu derste bağlantının hedef bölümü bulunamadı.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Görev bağlantısı kapalı ders içeriğini açar; editör/taslak korunur',
    (tester) async {
      final eski = oturumServisi;
      oturumServisi = denemeOturumu();
      addTearDown(() {
        oturumServisi.dispose();
        oturumServisi = eski;
      });
      final g = acik.gorevler.first;
      final servis = DersServisi()
        ..ders = Egitim(
          id: acik.id,
          kategoriId: acik.kategoriId,
          kod: acik.kod,
          baslik: acik.baslik,
          misafireAcik: true,
          erisilebilir: true,
          icerikMarkdown:
              '# Ders\n\n${araMetin()}\n## Alıştırmalar\n\n${araMetin()}',
          gorevler: [
            Gorev(
              id: g.id,
              egitimId: g.egitimId,
              no: g.no,
              baslik: g.baslik,
              tur: g.tur,
              baslangicDosyasi: g.baslangicDosyasi,
              baslangicKodu: g.baslangicKodu,
              kontrol: g.kontrol,
              aciklama: '[Konuya dön](#al%C4%B1%C5%9Ft%C4%B1rmalar)',
            ),
          ],
        );
      await tester.pumpWidget(
        MaterialApp(
          theme: acikTema,
          home: DersEkrani(ozet: acik, servis: servis),
        ),
      );
      await tester.pumpAndSettle();
      final editor = find.byKey(const ValueKey('kodEditoru'));
      await tester.ensureVisible(editor);
      await tester.enterText(editor, '    taslak\n');
      final link = find.byWidgetPredicate(
        (w) =>
            w is SelectableText &&
            (w.textSpan?.toPlainText() ?? '') == 'Konuya dön',
      );
      await tester.ensureVisible(link);
      await tester.pumpAndSettle();
      await tikla(tester, 'Konuya dön');
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ExpansionTile>(find.byType(ExpansionTile))
            .controller!
            .isExpanded,
        isTrue,
      );
      expect(
        tester.getTopLeft(metin('Alıştırmalar')).dy,
        inInclusiveRange(0, 140),
      );
      await tester.scrollUntilVisible(
        editor,
        300,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 50,
      );
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(editor).controller!.text, '    taslak\n');
      expect(tester.takeException(), isNull);
    },
  );
}
