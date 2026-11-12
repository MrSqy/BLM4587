import 'package:egitim_platformu/modeller/gorev.dart';
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
  baslangicKodu: 'ESKI DERS KODU KULLANILMAZ',
  gorevler: [
    Gorev(
      id: 101,
      egitimId: 7,
      no: 3,
      baslik: 'Selam',
      tur: 'kod',
      baslangicDosyasi: 'gorevler/selam.py',
      baslangicKodu: 'print(1)',
      kontrol: GorevKontrolu(
        beklenenCikti: '  Merhaba\n',
        beklenenCikisKodu: 2,
      ),
    ),
    Gorev(
      id: 203,
      egitimId: 7,
      no: 1,
      baslik: 'İkinci kod',
      tur: 'kod',
      baslangicDosyasi: 'gorevler/ikinci.py',
      baslangicKodu: '# ikinci',
      kontrol: GorevKontrolu(beklenenCikti: ''),
    ),
    Gorev(
      id: 310,
      egitimId: 7,
      no: 6,
      baslik: 'Açıkla',
      tur: 'aciklama',
      aciklama: 'Kabul ölçütü: Nedenini açıkla.',
    ),
  ],
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
  Egitim? ders;
  bool uye = false;
  bool oturumKontrolu = false;
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
      if (oturumKontrolu && !oturumServisi.girisYapildi) {
        throw const ApiHatasi('Giriş gerekli.', 401);
      }
      return ders ?? acik;
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
    'basarili',
    'basarisiz',
    'hata',
    'zaman_asimi',
    'cikti_siniri',
  ]) {
    testWidgets('görev testi $durum sonucu doğru sunulur', (tester) async {
      final istekler = <http.Request>[];
      final api = ApiIstemcisi(
        istemci: MockClient((r) async {
          istekler.add(r);
          return jsonYanit({
            'no': 3,
            'basarili': durum == 'basarili',
            'durum': durum,
            'cikti': durum == 'basarisiz' ? 'Merhaba' : '  Merhaba\n',
            'hata': '',
            'cikisKodu': durum == 'basarili'
                ? 2
                : durum == 'basarisiz'
                ? 0
                : null,
            'ciktiEslesiyor': durum == 'basarili'
                ? true
                : durum == 'basarisiz'
                ? false
                : null,
            'cikisKoduEslesiyor': durum == 'basarili'
                ? true
                : durum == 'basarisiz'
                ? false
                : null,
            'kuralIhlalleri': [],
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
      expect(
        istekler.single.url.path,
        '/api/mobil/egitimler/7/gorevler/3/test',
      );
      expect(istekler.single.body, '{"kod":"print(1)"}');
      final baslik = durum == 'basarili'
          ? 'Test geçti'
          : durum == 'zaman_asimi'
          ? 'Süre sınırı aşıldı'
          : durum == 'cikti_siniri'
          ? 'Çıktı sınırı aşıldı'
          : 'Test geçmedi';
      await tester.scrollUntilVisible(
        find.text(baslik),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(baslik), findsOneWidget);
      if (durum != 'basarili') {
        expect(find.text('Test geçti'), findsNothing);
      }
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('beklenenCikti')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester
            .widget<SelectableText>(find.byKey(const ValueKey('beklenenCikti')))
            .data,
        '  Merhaba\n',
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('gercekCikti')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester
            .widget<SelectableText>(find.byKey(const ValueKey('gercekCikti')))
            .data,
        durum == 'basarisiz' ? 'Merhaba' : '  Merhaba\n',
      );
    });
  }
  testWidgets(
    'görev seçimi dosyayı değiştirir; boş dahil bağımsız taslaklar korunur',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DersEkrani(ozet: acik, servis: DersServisi()),
        ),
      );
      await tester.pumpAndSettle();
      final editor = find.byKey(const ValueKey('kodEditoru'));
      await tester.ensureVisible(editor);
      await tester.enterText(editor, 'benim kodum');
      await tester.drag(find.byType(ListView).first, const Offset(0, 1500));
      await tester.pumpAndSettle();
      await butonaGit(tester, find.byKey(const ValueKey('gorev_203')));
      await tester.ensureVisible(editor);
      expect(tester.widget<TextField>(editor).controller!.text, '# ikinci');
      expect(
        tester.widget<TextField>(editor).decoration!.labelText,
        'gorevler/ikinci.py',
      );
      await tester.enterText(editor, '');
      await tester.drag(find.byType(ListView).first, const Offset(0, 1500));
      await tester.pumpAndSettle();
      await butonaGit(tester, find.byKey(const ValueKey('gorev_101')));
      await tester.ensureVisible(editor);
      expect(tester.widget<TextField>(editor).controller!.text, 'benim kodum');
      await tester.drag(find.byType(ListView).first, const Offset(0, 1500));
      await tester.pumpAndSettle();
      await butonaGit(tester, find.byKey(const ValueKey('gorev_203')));
      await tester.ensureVisible(editor);
      expect(tester.widget<TextField>(editor).controller!.text, '');
    },
  );
  testWidgets('açıklama görevi editör veya otomatik başarı göstermez', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DersEkrani(ozet: acik, servis: DersServisi()),
      ),
    );
    await tester.pumpAndSettle();
    await butonaGit(tester, find.byKey(const ValueKey('gorev_310')));
    expect(find.byKey(const ValueKey('kodEditoru')), findsNothing);
    expect(find.byKey(const ValueKey('kodTest')), findsNothing);
    expect(find.text('Kabul ölçütü: Nedenini açıkla.'), findsOneWidget);
    expect(find.text('Test geçti'), findsNothing);
  });
  testWidgets(
    'eski veya kontrolsüz görev aktarım gerektirir; eski endpoint çağrılmaz',
    (tester) async {
      final servis = DersServisi()
        ..ders = const Egitim(
          id: 7,
          kategoriId: 1,
          kod: 'PY',
          baslik: 'Eski',
          erisilebilir: true,
          gorevler: [Gorev(id: 42, egitimId: 7, no: 1, baslik: 'Eski')],
        );
      await tester.pumpWidget(
        MaterialApp(
          home: DersEkrani(ozet: acik, servis: servis),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('güncel içerik aktarımı gerekiyor'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('kodCalistir')), findsNothing);
    },
  );
  testWidgets(
    'çalıştır test başarısı değildir; yalnız kod ve görev no gönderilir',
    (tester) async {
      http.Request? req;
      final api = ApiIstemcisi(
        istemci: MockClient((r) async {
          req = r;
          return jsonYanit({
            'no': 3,
            'basarili': true,
            'durum': 'tamamlandi',
            'cikti': '',
            'hata': '',
            'cikisKodu': 0,
            'ciktiEslesiyor': null,
            'cikisKoduEslesiyor': null,
            'kuralIhlalleri': [],
          });
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: DersEkrani(ozet: acik, servis: DersServisi(), api: api),
        ),
      );
      await tester.pumpAndSettle();
      await butonaGit(tester, find.byKey(const ValueKey('kodCalistir')));
      expect(req!.url.path, '/api/mobil/egitimler/7/gorevler/3/calistir');
      expect(req!.body, '{"kod":"print(1)"}');
      await tester.scrollUntilVisible(
        find.text('Çalıştırma tamamlandı'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Test geçti'), findsNothing);
    },
  );
  testWidgets(
    'çalıştırma 20 saniyeyi geçebilir; çift gönderim engellenir ve 503 sonrası düğme açılır',
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
      await tester.pump(const Duration(seconds: 21));
      expect(tester.widget<FilledButton>(dugme).onPressed, isNull);
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
    await tester.tap(find.text('Ders içeriği'));
    await tester.pumpAndSettle();
    expect(find.text('Üyeye özel içerik'), findsOneWidget);
    servis.uye = false;
    await oturumServisi.temizle();
    await tester.pumpAndSettle();
    expect(find.text('Üyeye özel içerik'), findsNothing);
    expect(find.text('Giriş yap'), findsOneWidget);
  });
  for (final misafireAcik in [true, false]) {
    testWidgets(
      'oturum süresi dolunca taslaklar korunur (misafir erişimi: $misafireAcik)',
      (tester) async {
        tester.view.physicalSize = const Size(900, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var simdi = DateTime.utc(2026, 11, 12);
        oturumServisi.dispose();
        oturumServisi = OturumServisi(
          ApiIstemcisi(
            istemci: MockClient(
              (_) async => jsonYanit(
                oturumYaniti(bitis: simdi.add(const Duration(minutes: 15))),
              ),
            ),
          ),
          BellekDeposu(),
          simdi: () => simdi,
        );
        await oturumServisi.giris('ogrenci@ornek.com', 'Deneme123!');
        final ders = Egitim(
          id: acik.id,
          kategoriId: acik.kategoriId,
          kod: acik.kod,
          baslik: acik.baslik,
          erisilebilir: true,
          misafireAcik: misafireAcik,
          gorevler: acik.gorevler,
        );
        final servis = DersServisi()
          ..ders = ders
          ..oturumKontrolu = !misafireAcik;
        await tester.pumpWidget(
          MaterialApp(
            home: DersEkrani(ozet: ders, servis: servis),
          ),
        );
        await tester.pumpAndSettle();
        final editor = find.byKey(const ValueKey('kodEditoru'));
        final birinci = find.byKey(const ValueKey('gorev_101'));
        final ikinci = find.byKey(const ValueKey('gorev_203'));
        await tester.enterText(editor, '  ilk taslak\n');
        await tester.tap(ikinci);
        await tester.pumpAndSettle();
        await tester.enterText(editor, 'ikinci taslak');

        simdi = simdi.add(const Duration(minutes: 15));
        await tester.pump(const Duration(minutes: 15));
        await tester.pumpAndSettle();
        expect(oturumServisi.girisYapildi, isFalse);
        if (!misafireAcik) {
          expect(editor, findsNothing);
          expect(find.text('Giriş yap'), findsOneWidget);
          await oturumServisi.giris('ogrenci@ornek.com', 'Deneme123!');
          await tester.pumpAndSettle();
        }
        expect(tester.widget<ChoiceChip>(ikinci).selected, isTrue);
        expect(
          tester.widget<TextField>(editor).controller!.text,
          'ikinci taslak',
        );
        await tester.tap(birinci);
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(editor).controller!.text,
          '  ilk taslak\n',
        );
      },
    );
  }

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
