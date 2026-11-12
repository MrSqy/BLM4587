import 'dart:async';
import 'dart:convert';

import 'package:egitim_platformu/ekranlar/ilerleme_ekrani.dart';
import 'package:egitim_platformu/servisler/api_istemcisi.dart';
import 'package:egitim_platformu/servisler/gonderim_servisi.dart';
import 'package:egitim_platformu/servisler/oturum_servisi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'destek/oturum_destegi.dart';

Map<String, dynamic> _ozet(int id) => {
  'id': id,
  'tarih': '2026-11-12T15:45:00+00:00',
  'egitimId': 1,
  'ders': 'Ders $id',
  'gorevId': null,
  'gorevNo': null,
  'gorev': null,
  'durum': 'basarili',
  'basarili': true,
  'cikisKodu': 0,
  'sureMs': 238,
};

Map<String, dynamic> _sayfa(int sayfa, int toplam, List<int> ids) => {
  'toplam': toplam,
  'sayfa': sayfa,
  'sayfaBoyutu': 20,
  'kayitlar': ids.map(_ozet).toList(),
};

void main() {
  late OturumServisi onceki;

  setUp(() => onceki = oturumServisi);
  tearDown(() {
    if (!identical(oturumServisi, onceki)) oturumServisi.dispose();
    oturumServisi = onceki;
  });

  ApiIstemcisi kur(Future<http.Response> Function(http.Request) yanit) {
    final api = ApiIstemcisi(
      adres: 'https://egitim.example.test/api/mobil/',
      istemci: MockClient((req) async {
        if (req.url.path.endsWith('/hesap/giris')) {
          final eposta = (jsonDecode(req.body) as Map)['eposta'] as String;
          return jsonYanit({
            ...oturumYaniti(),
            'token': 'token-$eposta',
            'kullanici': {'id': eposta, 'eposta': eposta, 'adSoyad': 'Öğrenci'},
          });
        }
        return yanit(req);
      }),
    );
    oturumServisi = OturumServisi(api, BellekDeposu());
    return api;
  }

  Widget ekran(ApiIstemcisi api, {bool etkin = true}) => MaterialApp(
    home: Scaffold(
      body: IlerlemeEkrani(etkin: etkin, servis: GonderimServisi(api)),
    ),
  );

  testWidgets('aynı sunucuda Bearer liste, ikinci sayfa ve ayrıntı', (
    tester,
  ) async {
    final istekler = <Uri>[];
    final api = kur((req) async {
      istekler.add(req.url);
      expect(req.url.origin, 'https://egitim.example.test');
      expect(req.headers['Authorization'], 'Bearer token-bir@example.test');
      if (req.url.path == '/api/gonderimler/22') {
        return jsonYanit({
          'gonderim': _ozet(22),
          'kod': 'print(1)',
          'cikti': '  1\n',
          'hata': '',
        });
      }
      expect(req.url.path, '/api/gonderimler');
      expect(req.url.queryParameters['sayfaBoyutu'], '20');
      return req.url.queryParameters['sayfa'] == '1'
          ? jsonYanit(_sayfa(1, 21, List.generate(20, (i) => 42 - i)))
          : jsonYanit(_sayfa(2, 21, [22]));
    });
    await oturumServisi.giris('bir@example.test', 'Deneme123!');
    await tester.pumpWidget(ekran(api));
    await tester.pumpAndSettle();
    expect(find.text('21 gönderim'), findsOneWidget);
    final dahaFazla = find.text('Daha fazla göster');
    await tester.scrollUntilVisible(dahaFazla, 300);
    await tester.tap(dahaFazla);
    await tester.pumpAndSettle();
    expect(istekler[1].queryParameters['sayfa'], '2');
    final kayit = find.byKey(const ValueKey('gonderim_22'));
    await tester.ensureVisible(kayit);
    await tester.tap(kayit);
    await tester.pumpAndSettle();
    expect(find.text('Gönderim #22'), findsOneWidget);
    expect(find.text('print(1)'), findsOneWidget);
    expect(find.text('  1\n'), findsOneWidget);
    await oturumServisi.temizle();
    await tester.pumpAndSettle();
    expect(find.text('print(1)'), findsNothing);
    expect(
      find.text('Gönderimi görmek için geçmişi yeniden aç.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'gizli sekme istek atmaz; eski hesaptan geç gelen liste gizlenir',
    (tester) async {
      final eskiYaniti = Completer<http.Response>();
      var sayi = 0;
      final api = kur((req) async {
        sayi++;
        if (req.headers['Authorization'] == 'Bearer token-bir@example.test') {
          return eskiYaniti.future;
        }
        return jsonYanit(_sayfa(1, 1, [80]));
      });
      await oturumServisi.giris('bir@example.test', 'Deneme123!');
      await tester.pumpWidget(ekran(api, etkin: false));
      await tester.pumpAndSettle();
      expect(sayi, 0);

      await tester.pumpWidget(ekran(api));
      await tester.pump();
      expect(sayi, 1);
      await oturumServisi.temizle();
      await tester.pumpAndSettle();
      expect(find.text('Giriş yap'), findsOneWidget);

      await oturumServisi.giris('iki@example.test', 'Deneme123!');
      await tester.pumpAndSettle();
      expect(find.text('Ders 80'), findsOneWidget);
      eskiYaniti.complete(jsonYanit(_sayfa(1, 1, [42])));
      await tester.pumpAndSettle();
      expect(find.text('Ders 42'), findsNothing);
      expect(find.text('Ders 80'), findsOneWidget);
    },
  );

  testWidgets('geçmiş 503 hatası boş liste olarak gösterilmez', (tester) async {
    var ilk = true;
    final api = kur((_) async {
      if (ilk) {
        ilk = false;
        return jsonYanit({'mesaj': 'Geçmiş şu anda kullanılamıyor.'}, 503);
      }
      return jsonYanit(_sayfa(1, 0, []));
    });
    await oturumServisi.giris('bir@example.test', 'Deneme123!');
    await tester.pumpWidget(ekran(api));
    await tester.pumpAndSettle();
    expect(find.text('Geçmiş şu anda kullanılamıyor.'), findsOneWidget);
    expect(find.text('Henüz gönderimin yok.'), findsNothing);
    await tester.tap(find.text('Tekrar dene'));
    await tester.pumpAndSettle();
    expect(find.text('Henüz gönderimin yok.'), findsOneWidget);
  });

  test(
    'sabit geçmiş yolu dışında mobil öneki ve origin sınırı korunur',
    () async {
      var sayi = 0;
      final api = kur((_) async {
        sayi++;
        return jsonYanit(_sayfa(1, 0, []));
      });
      await expectLater(
        api.iste('/api/gonderimler'),
        throwsA(isA<ApiHatasi>()),
      );
      await expectLater(
        api.iste('https://baska.example.test/api/mobil/egitimler'),
        throwsA(isA<ApiHatasi>()),
      );
      expect(sayi, 0);
      expect((await GonderimServisi(api).liste(1)).toplam, 0);
      expect(sayi, 1);
    },
  );
}
