import 'dart:async';

import 'package:egitim_platformu/ekranlar/egitimler_ekrani.dart';
import 'package:egitim_platformu/modeller/egitim.dart';
import 'package:egitim_platformu/modeller/kategori.dart';
import 'package:egitim_platformu/servisler/egitim_servisi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class DenemeServisi implements EgitimServisi {
  final kategoriler = const [
    Kategori(id: 1, ad: 'Python', kisaltma: 'PY'),
    Kategori(id: 2, ad: 'Teknik Mülakat Algoritmalar', kisaltma: 'TMA'),
    Kategori(id: 3, ad: 'Boş kategori', kisaltma: 'B'),
  ];
  List<Egitim> dersler = const [
    Egitim(id: 1, kategoriId: 1, kod: 'PY-01', baslik: 'Python başlangıç'),
    Egitim(id: 2, kategoriId: 2, kod: 'TMA-01', baslik: 'Algoritma başlangıç'),
  ];
  bool hata = false;
  int istekSayisi = 0;
  Completer<void>? bekleme;

  @override
  Future<List<Kategori>> kategorileriGetir() async {
    istekSayisi++;
    if (bekleme != null) await bekleme!.future;
    if (hata) throw Exception('Deneme hatası');
    return kategoriler;
  }

  @override
  Future<List<Egitim>> egitimleriGetir({int? kategoriId}) async => dersler
      .where((e) => kategoriId == null || e.kategoriId == kategoriId)
      .toList();

  @override
  Future<Egitim?> egitimGetir(int id) async => null;
}

Future<void> ekraniAc(WidgetTester tester, DenemeServisi servis) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: EgitimlerEkrani(servis: servis)),
    ),
  );
  await tester.pump();
}

Future<void> sec(WidgetTester tester, String anahtar) async {
  final kart = find.byKey(ValueKey(anahtar));
  await tester.ensureVisible(kart);
  await tester.tap(kart);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'kategoriler filtreler, Tümü geri getirir ve yeniden veri istemez',
    (tester) async {
      final servis = DenemeServisi();
      await ekraniAc(tester, servis);
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Dersler (2)'), findsOneWidget);
      await sec(tester, 'kategori_2');
      expect(find.text('Dersler (1)'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('ders_2')));
      expect(find.text('Algoritma başlangıç'), findsOneWidget);
      expect(find.text('Python başlangıç'), findsNothing);
      await sec(tester, 'tumKategoriler');
      expect(find.text('Dersler (2)'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('ders_1')));
      expect(find.text('Python başlangıç'), findsOneWidget);
      expect(servis.istekSayisi, 1);
    },
  );

  testWidgets('boş kategori ve tümü boş veri ayrı mesaj verir', (tester) async {
    final servis = DenemeServisi();
    await ekraniAc(tester, servis);
    await tester.pumpAndSettle();
    await sec(tester, 'kategori_3');
    await tester.ensureVisible(find.text('Bu kategoride henüz eğitim yok.'));
    expect(find.text('Bu kategoride henüz eğitim yok.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    servis.dersler = [];
    await ekraniAc(tester, servis);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Henüz eğitim eklenmemiş.'));
    expect(find.text('Henüz eğitim eklenmemiş.'), findsOneWidget);
  });

  testWidgets('yükleniyor, hata ve tekrar deneme durumları', (tester) async {
    final servis = DenemeServisi()
      ..bekleme = Completer<void>()
      ..hata = true;
    await ekraniAc(tester, servis);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    servis.bekleme!.complete();
    await tester.pumpAndSettle();
    expect(
      find.text('Eğitimler yüklenemedi. Lütfen tekrar deneyin.'),
      findsOneWidget,
    );
    servis.hata = false;
    await tester.tap(find.text('Tekrar dene'));
    await tester.pumpAndSettle();
    expect(find.text('Dersler (2)'), findsOneWidget);
    expect(servis.istekSayisi, 2);
  });

  testWidgets('dar ekranda büyük yazıyla kategori kartları taşmaz', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(body: EgitimlerEkrani(servis: DenemeServisi())),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await sec(tester, 'kategori_2');
    expect(tester.takeException(), isNull);
  });
}
