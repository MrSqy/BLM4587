import 'dart:async';
import 'package:egitim_platformu/ekranlar/ders_ekrani.dart';
import 'package:egitim_platformu/ekranlar/egitimler_ekrani.dart';
import 'package:egitim_platformu/modeller/egitim.dart';
import 'package:egitim_platformu/modeller/kategori.dart';
import 'package:egitim_platformu/servisler/api_istemcisi.dart';
import 'package:egitim_platformu/servisler/egitim_servisi.dart';
import 'package:egitim_platformu/servisler/oturum_servisi.dart';
import 'package:egitim_platformu/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'destek/oturum_destegi.dart';

const acik = Egitim(
  id: 7,
  kategoriId: 1,
  kod: 'PY-07',
  baslik: 'Açık ders',
  misafireAcik: true,
  erisilebilir: true,
  icerikMarkdown: '# Ders içeriği',
  baslangicKodu: 'print(1)',
);
const kapali = Egitim(
  id: 1,
  kategoriId: 1,
  kod: 'PY-01',
  baslik: 'Üye dersi',
  misafireAcik: false,
  erisilebilir: false,
  ozet: 'Sadece müfredat özeti.',
);

class DersServisi implements EgitimServisi {
  int detayIstegi = 0;
  bool uye = false;
  @override
  Future<List<Kategori>> kategorileriGetir() async => [
    const Kategori(id: 1, ad: 'Python', kisaltma: 'PY'),
  ];
  @override
  Future<List<Egitim>> egitimleriGetir({int? kategoriId}) async => [
    acik,
    kapali,
  ];
  @override
  Future<Egitim?> egitimGetir(int id) async {
    detayIstegi++;
    if (id == 7) {
      return acik;
    }
    if (!uye) {
      throw const ApiHatasi('Giriş gerekli.', 401);
    }
    return const Egitim(
      id: 1,
      kategoriId: 1,
      kod: 'PY-01',
      baslik: 'Üye dersi',
      erisilebilir: true,
      icerikMarkdown: 'Üyeye özel içerik',
      baslangicKodu: 'print(2)',
    );
  }
}

Future<void> butonaGit(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    250,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 50,
  );
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  late OturumServisi eski;
  setUp(() {
    eski = oturumServisi;
    oturumServisi = denemeOturumu();
  });
  tearDown(() {
    oturumServisi.dispose();
    oturumServisi = eski;
  });
  testWidgets(
    'misafir ilk sırayı tahmin etmez; API açık dersi açar, kapalı ders yalnız özet',
    (tester) async {
      final servis = DersServisi();
      await tester.pumpWidget(
        MaterialApp(
          theme: acikTema,
          home: Scaffold(body: EgitimlerEkrani(servis: servis)),
        ),
      );
      await tester.pumpAndSettle();
      await butonaGit(tester, find.byKey(const ValueKey('ders_1')));
      expect(find.textContaining('Sadece müfredat özeti.'), findsOneWidget);
      expect(servis.detayIstegi, 0);
      await tester.tap(find.text('Müfredata dön'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, 500));
      await tester.pumpAndSettle();
      await butonaGit(tester, find.byKey(const ValueKey('ders_7')));
      expect(find.text('Ders içeriği'), findsOneWidget);
      expect(servis.detayIstegi, 1);
    },
  );
  for (final durum in [
    'tamamlandi',
    'basarisiz',
    'hata',
    'zaman_asimi',
    'test_yok',
  ]) {
    testWidgets('runner $durum sonucu doğru sunulur', (tester) async {
      final istekler = <http.Request>[];
      final api = ApiIstemcisi(
        istemci: MockClient((r) async {
          istekler.add(r);
          return jsonYanit({
            'basarili': durum == 'tamamlandi',
            'durum': durum,
            'cikti': 'Örnek çıktı',
            'hata': '',
            'gorevler': [
              {'no': 1, 'durum': 'basarili'},
              {'no': 2, 'durum': 'basarisiz'},
              {'no': 3, 'durum': 'atlanmis'},
              {'no': 4, 'durum': 'test_yok'},
            ],
          });
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: acikTema,
          home: DersEkrani(ozet: acik, servis: DersServisi(), api: api),
        ),
      );
      await tester.pumpAndSettle();
      await butonaGit(tester, find.byKey(const ValueKey('kodTest')));
      expect(istekler.single.url.path, '/api/mobil/egitimler/7/test');
      expect(istekler.single.body, '{"kod":"print(1)"}');
      final baslik = durum == 'tamamlandi'
          ? 'Çalışma tamamlandı'
          : durum == 'zaman_asimi'
          ? 'Süre sınırı aşıldı'
          : durum == 'test_yok'
          ? 'Otomatik test bulunamadı'
          : 'Kodunu gözden geçir';
      await tester.scrollUntilVisible(
        find.text(baslik),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(baslik), findsOneWidget);
      if (durum != 'tamamlandi') {
        expect(find.text('Çalışma tamamlandı'), findsNothing);
      }
      await tester.scrollUntilVisible(
        find.text('Testler geçmedi'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Testler geçmedi'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Otomatik test yok; dersin kabul ölçütlerini kontrol et.'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('Otomatik test yok; dersin kabul ölçütlerini kontrol et.'),
        findsOneWidget,
      );
    });
  }
  testWidgets(
    'çalıştır isteği beklerken çift gönderim engellenir; 503 yeniden denemeye izin verir',
    (tester) async {
      final cevap = Completer<http.Response>();
      var sayi = 0;
      final api = ApiIstemcisi(
        istemci: MockClient((_) {
          sayi++;
          return cevap.future;
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: DersEkrani(ozet: acik, servis: DersServisi(), api: api),
        ),
      );
      await tester.pumpAndSettle();
      final dugme = find.byKey(const ValueKey('kodCalistir'));
      await tester.scrollUntilVisible(
        dugme,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(dugme);
      await tester.pump();
      expect(tester.widget<FilledButton>(dugme).onPressed, isNull);
      expect(sayi, 1);
      cevap.complete(http.Response('', 503));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(dugme).onPressed, isNotNull);
      await tester.scrollUntilVisible(
        find.textContaining('Servis şu anda'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Servis şu anda'), findsOneWidget);
    },
  );
  testWidgets('çıkıştan sonra açık korunan ders içeriği kaldırılır', (
    tester,
  ) async {
    final servis = DersServisi()..uye = true;
    await oturumServisi.giris('ogrenci@ornek.com', 'Deneme123!');
    await tester.pumpWidget(
      MaterialApp(
        home: DersEkrani(ozet: kapali, servis: servis),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Üyeye özel içerik'), findsOneWidget);
    servis.uye = false;
    await oturumServisi.temizle();
    await tester.pumpAndSettle();
    expect(find.text('Üyeye özel içerik'), findsNothing);
    expect(find.text('Giriş yap'), findsOneWidget);
  });
  for (final tema in [acikTema, koyuTema]) {
    testWidgets('dar yatay görünüm ve büyük yazı ${tema.brightness}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(640, 320);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: tema,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: DersEkrani(ozet: acik, servis: DersServisi()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('kodTest')),
        200,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 50,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
