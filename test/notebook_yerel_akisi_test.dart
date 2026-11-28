import 'dart:io';

import 'package:egitim_platformu/ekranlar/notebook_goruntuleyici_ekrani.dart';
import 'package:egitim_platformu/modeller/notebook.dart';
import 'package:egitim_platformu/servisler/notebook_depolama.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _menu = 'Notebook dosyaları';
const _taslakKaydet = 'Taslak olarak kaydet';
const _kaydet = 'Cihaza kaydet';
const _taslagiAc = 'Taslağı aç';
const _kaydiAc = 'Kaydedilen notebook’u aç';
const _duzenle = ValueKey('notebookDuzenle');
const _kaynak = ValueKey('hucreKaynagi');
const _uyari = ValueKey('kaydedilmediUyarisi');

class _BellekteDepolama extends NotebookDepolama {
  final Map<NotebookYerelKopya, NotebookBelgesi> kopyalar = {};
  bool yazmaHatasi = false;

  @override
  Future<NotebookBelgesi?> oku(NotebookYerelKopya kopya) async =>
      kopyalar[kopya];

  @override
  Future<void> yaz(NotebookYerelKopya kopya, NotebookBelgesi belge) async {
    if (yazmaHatasi) throw const FileSystemException('disk dolu');
    kopyalar[kopya] = belge;
  }
}

Future<void> _ac(WidgetTester tester, NotebookDepolama depolama) async {
  await tester.pumpWidget(
    MaterialApp(
      home: OrnekNotebookEkrani(
        depolama: depolama,
        yukleyici: () async => NotebookBelgesi.fromJsonString(
          '{"nbformat":4,"nbformat_minor":5,"metadata":{},"cells":'
          '[{"id":"md","cell_type":"markdown","metadata":{},"source":"# Örnek"}]}',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _sec(WidgetTester tester, String eylem) async {
  await tester.tap(find.byTooltip(_menu));
  await tester.pumpAndSettle();
  await tester.tap(find.text(eylem));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('kayıt ve taslak yeni oturumda menüden ayrı ayrı açılır', (
    tester,
  ) async {
    final depolama = _BellekteDepolama();
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _ac(tester, depolama);
    await tester.tap(find.byKey(_duzenle));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(_kaynak), '# Kaydedilen sürüm');
    await _sec(tester, _kaydet);
    expect(find.byKey(_uyari), findsNothing);

    await tester.enterText(find.byKey(_kaynak), '# Taslak sürüm');
    await _sec(tester, _taslakKaydet);
    expect(find.byKey(_uyari), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await _ac(tester, depolama);
    await _sec(tester, _taslagiAc);
    expect(find.text('Taslak sürüm'), findsOneWidget);
    await tester.tap(find.byKey(_duzenle));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byKey(_kaynak)).controller?.text,
      '# Taslak sürüm',
    );
    await _sec(tester, _kaydiAc);
    expect(find.text('Kaydedilen sürüm'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('yazma hatası ve açmaktan vazgeçme düzenlemeyi korur', (
    tester,
  ) async {
    final depolama = _BellekteDepolama();
    await _ac(tester, depolama);
    await _sec(tester, _kaydet);
    depolama.yazmaHatasi = true;
    await tester.tap(find.byKey(_duzenle));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(_kaynak), '# Yeni içerik');
    await _sec(tester, _taslakKaydet);

    expect(find.text('Taslak kaydedilemedi.'), findsOneWidget);
    expect(find.byKey(_uyari), findsOneWidget);

    await _sec(tester, _kaydiAc);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byKey(_kaynak)).controller?.text,
      '# Yeni içerik',
    );

    await _sec(tester, _kaydiAc);
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
    expect(find.text('Örnek'), findsOneWidget);
    expect(find.byKey(_uyari), findsNothing);
  });
}
