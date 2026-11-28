import 'package:egitim_platformu/ekranlar/ana_iskelet.dart';
import 'package:egitim_platformu/modeller/egitim.dart';
import 'package:egitim_platformu/modeller/kategori.dart';
import 'package:egitim_platformu/servisler/egitim_servisi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Sunucuda içerik değişmiş gibi davranabilen sahte servis.
class _DegisenServis implements EgitimServisi {
  List<Egitim> dersler = [];

  @override
  Future<List<Kategori>> kategorileriGetir() async => const [
    Kategori(id: 2, ad: 'Teknik Mülakat Algoritmalar', kisaltma: 'TMA'),
  ];

  @override
  Future<List<Egitim>> egitimleriGetir({int? kategoriId}) async => dersler
      .where((e) => kategoriId == null || e.kategoriId == kategoriId)
      .toList();

  @override
  Future<Egitim?> egitimGetir(int id) async => null;
}

void main() {
  testWidgets('sekmeye dönünce içerik değişikliği görünür', (tester) async {
    final servis = _DegisenServis();
    egitimServisi = servis;
    await tester.pumpWidget(const MaterialApp(home: AnaIskelet()));
    await tester.pumpAndSettle();
    expect(find.text('0 ders'), findsOneWidget);

    // Eğitimler sekmesi ilk kez açılırken boş liste yüklenir.
    await tester.tap(find.text('Eğitimler').last);
    await tester.pumpAndSettle();
    expect(find.text('Kurulum'), findsNothing);

    // Sunucuya üç ders eklendi (A komutu).
    servis.dersler = [
      for (final (i, baslik) in const [
        'Kurulum',
        'Karmaşıklık analizi',
        'Diziler ve stringler',
      ].indexed)
        Egitim(id: 10 + i, kategoriId: 2, kod: 'TMA-0$i', baslik: baslik),
    ];

    await tester.tap(find.text('Ana sayfa'));
    await tester.pumpAndSettle();
    expect(find.text('3 ders'), findsOneWidget);

    await tester.tap(find.text('Eğitimler').last);
    await tester.pumpAndSettle();
    expect(find.text('Kurulum'), findsOneWidget);
    expect(find.text('3 ders'), findsOneWidget);

    // Dersler kaldırıldı (B komutu); kategori kalır, sayı sıfırlanır.
    servis.dersler = [];
    await tester.tap(find.text('Ana sayfa'));
    await tester.pumpAndSettle();
    expect(find.text('0 ders'), findsOneWidget);
    expect(find.text('Teknik Mülakat Algoritmalar'), findsOneWidget);
  });
}
