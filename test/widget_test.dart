import 'package:egitim_platformu/servisler/egitim_servisi.dart';
import 'package:egitim_platformu/uygulama.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Asset dosyası gerçek bir okuma işlemiyle yüklenir; testWidgets'ın sahte saatinde
  // bu işlem bitmez. Bu yüzden veriyi testlerden önce bir kez yükleyip servisi paylaşıyoruz.
  setUpAll(() async {
    final servis = SahteEgitimServisi(gecikme: Duration.zero);
    await servis.kategorileriGetir();
    egitimServisi = servis;
  });

  testWidgets('ana sayfa sahte veriden özeti gösterir', (tester) async {
    await tester.pumpWidget(const EgitimUygulamasi());
    await tester.pumpAndSettle();

    expect(find.text('Hoş geldin!'), findsOneWidget);
    expect(find.text('24'), findsOneWidget); // görev sayısı
    expect(find.text('Python dili'), findsOneWidget);
  });

  testWidgets('alt menüde dört sekme var ve sekmeler değişir', (tester) async {
    await tester.pumpWidget(const EgitimUygulamasi());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationDestination), findsNWidgets(4));

    await tester.tap(find.text('Eğitimler').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Ders listesi ve kategori filtresi burada olacak.'),
      findsOneWidget,
    );
  });

  testWidgets('profilden isimli rotayla Hakkında sayfasına gidilir', (
    tester,
  ) async {
    await tester.pumpWidget(const EgitimUygulamasi());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hakkında'));
    await tester.pumpAndSettle();

    expect(find.text('Etkileşimli Eğitim Platformu'), findsOneWidget);
  });
}
