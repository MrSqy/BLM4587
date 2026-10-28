import 'package:egitim_platformu/ekranlar/profil_ekrani.dart';
import 'package:egitim_platformu/rotalar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> formuAc(WidgetTester tester, {bool kayit = false}) async {
  await tester.pumpWidget(
    MaterialApp(
      initialRoute: kayit ? Rotalar.kayit : Rotalar.giris,
      routes: {...Rotalar.tablo, '/': (_) => const Scaffold()},
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> gonder(WidgetTester tester) async {
  final dugme = find.byKey(const ValueKey('formGonder'));
  await tester.ensureVisible(dugme);
  await tester.tap(dugme);
  await tester.pumpAndSettle();
}

Future<void> yaz(WidgetTester tester, String alan, String metin) async {
  final girdi = find.byKey(ValueKey(alan));
  await tester.ensureVisible(girdi);
  await tester.enterText(girdi, metin);
  await tester.pump();
}

void main() {
  testWidgets('girişte boş ve geçersiz alanlar reddedilir', (tester) async {
    await formuAc(tester);
    await gonder(tester);
    expect(find.text('E-posta zorunludur.'), findsOneWidget);
    expect(find.text('Şifre zorunludur.'), findsOneWidget);
    await yaz(tester, 'eposta', 'bozuk@adres');
    await yaz(tester, 'sifre', '1234567');
    await gonder(tester);
    expect(find.text('Geçerli bir e-posta adresi girin.'), findsOneWidget);
    expect(find.text('Şifre en az 8 karakter olmalıdır.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('geçerli giriş yalnızca demo bildirimi gösterir', (tester) async {
    await formuAc(tester);
    await yaz(tester, 'eposta', '  ogrenci@ornek.com  ');
    await yaz(tester, 'sifre', '12345678');
    await gonder(tester);
    expect(find.text('Demo form doğrulandı'), findsOneWidget);
    expect(find.textContaining('oturum açılmadı.'), findsOneWidget);
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('formGonder')), findsOneWidget);
  });

  testWidgets('kayıtta zorunlu alanlar ve şifre tekrarı doğrulanır', (
    tester,
  ) async {
    await formuAc(tester, kayit: true);
    await gonder(tester);
    expect(find.text('Ad soyad zorunludur.'), findsOneWidget);
    expect(find.text('Şifre tekrarı zorunludur.'), findsOneWidget);
    await yaz(tester, 'adSoyad', '   ');
    await yaz(tester, 'eposta', 'ogrenci@ornek.com');
    await yaz(tester, 'sifre', '12345678');
    await yaz(tester, 'sifreTekrari', '12345679');
    await gonder(tester);
    expect(find.text('Ad soyad zorunludur.'), findsOneWidget);
    expect(find.text('Şifreler eşleşmiyor.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    await yaz(tester, 'adSoyad', 'Örnek Öğrenci');
    await yaz(tester, 'sifreTekrari', '12345678');
    await gonder(tester);
    expect(find.textContaining('hesap oluşturulmadı'), findsOneWidget);
  });

  testWidgets('şifre gizlenir ve görünürlük değiştirilebilir', (tester) async {
    await formuAc(tester);
    TextField sifre() => tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('sifre')),
        matching: find.byType(TextField),
      ),
    );
    expect(sifre().obscureText, isTrue);
    await tester.tap(find.byTooltip('Şifreyi göster'));
    await tester.pump();
    expect(sifre().obscureText, isFalse);
  });

  testWidgets('profilden formlara gidilir ve geri dönünce misafir kalır', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          ...Rotalar.tablo,
          '/': (_) => const Scaffold(body: ProfilEkrani()),
        },
      ),
    );
    await tester.tap(find.text('Giriş yap'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Hesabın yok mu? Kayıt ol'));
    await tester.tap(find.text('Hesabın yok mu? Kayıt ol'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('adSoyad')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Misafir'), findsOneWidget);
    expect(find.text('Henüz giriş yapılmadı'), findsOneWidget);
  });
}
