import 'dart:async';
import 'dart:convert';
import 'package:egitim_platformu/servisler/api_istemcisi.dart';
import 'package:egitim_platformu/servisler/oturum_servisi.dart';
import 'package:egitim_platformu/servisler/egitim_servisi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'destek/oturum_destegi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'giriş/kayıt sözleşmesi, Bearer, çıkış ve depodan geri yükleme',
    () async {
      final depo = BellekDeposu();
      final istekler = <http.Request>[];
      final api = ApiIstemcisi(
        istemci: MockClient((r) async {
          istekler.add(r);
          return r.url.path.endsWith('cikis')
              ? http.Response('', 204)
              : jsonYanit(oturumYaniti());
        }),
      );
      final servis = OturumServisi(api, depo);
      addTearDown(servis.dispose);
      await servis.giris(
        ' ogrenci@ornek.com ',
        'Deneme123!',
        adSoyad: ' Öğrenci ',
      );
      expect(istekler.first.url.path, '/api/mobil/hesap/kayit');
      expect(jsonDecode(istekler.first.body), {
        'eposta': 'ogrenci@ornek.com',
        'sifre': 'Deneme123!',
        'adSoyad': 'Öğrenci',
      });
      expect(istekler.first.headers.containsKey('Authorization'), isFalse);
      expect(depo.veri, isNot(contains('Deneme123!')));
      final yeniden = OturumServisi(ApiIstemcisi(), depo);
      addTearDown(yeniden.dispose);
      await yeniden.hazirla();
      expect(yeniden.girisYapildi, isTrue);
      await servis.cikis();
      expect(istekler.last.headers['Authorization'], 'Bearer test-token');
      expect(depo.veri, isNull);
      expect(servis.girisYapildi, isFalse);
    },
  );

  for (final kod in [401, 403, 409, 429, 503]) {
    test('$kod için mesaj ve doğru oturum temizleme davranışı', () async {
      final depo = BellekDeposu()..veri = jsonEncode(oturumYaniti());
      final api = ApiIstemcisi(
        istemci: MockClient((_) async => http.Response('', kod)),
      );
      final servis = OturumServisi(api, depo);
      addTearDown(servis.dispose);
      await servis.hazirla();
      await expectLater(
        api.iste('egitimler/2'),
        throwsA(
          isA<ApiHatasi>()
              .having((e) => e.durum, 'durum', kod)
              .having((e) => e.mesaj, 'mesaj', isNotEmpty),
        ),
      );
      expect(servis.girisYapildi, kod != 401);
      expect(depo.veri != null, kod != 401);
    });
  }
  test('ProblemDetails errors, title ve mesaj okunur', () async {
    for (final sample in [
      (
        {
          'errors': {
            'Eposta': ['E-posta hatalı.'],
            'Sifre': ['Şifre kısa.'],
          },
          'title': 'Doğrulama',
        },
        'E-posta hatalı.\nŞifre kısa.',
      ),
      ({'title': 'Yetki yok'}, 'Yetki yok'),
      ({'mesaj': 'Özel hata'}, 'Özel hata'),
    ]) {
      final api = ApiIstemcisi(
        istemci: MockClient((_) async => jsonYanit(sample.$1, 400)),
      );
      await expectLater(
        api.iste('hesap/ben'),
        throwsA(isA<ApiHatasi>().having((e) => e.mesaj, 'mesaj', sample.$2)),
      );
    }
  });
  test('bozuk yanıt ve HTTPS zorunluluğu sessiz başarı sayılmaz', () async {
    final api = ApiIstemcisi(
      istemci: MockClient((_) async => http.Response('html', 200)),
    );
    await expectLater(api.iste('kategoriler'), throwsA(isA<ApiHatasi>()));
    final yayin = ApiIstemcisi(
      adres: 'http://localhost/api/mobil/',
      httpsZorunlu: true,
    );
    await expectLater(yayin.iste('kategoriler'), throwsA(isA<ApiHatasi>()));
  });
  test('gecikmiş 401 yeni tokenı silmez', () async {
    final cevap = Completer<http.Response>();
    final api = ApiIstemcisi(istemci: MockClient((_) => cevap.future));
    var token = 'eski';
    var silindi = false;
    api.tokenOku = () => token;
    api.oturumGecersiz = () async {
      silindi = true;
    };
    final istek = api.iste('hesap/ben');
    token = 'yeni';
    cevap.complete(http.Response('', 401));
    await expectLater(istek, throwsA(isA<ApiHatasi>()));
    expect(silindi, isFalse);
  });
  testWidgets('15 dakikalık oturum süre sonunda temizlenir', (tester) async {
    var simdi = DateTime.utc(2026, 11, 2);
    final depo = BellekDeposu()
      ..veri = jsonEncode(
        oturumYaniti(bitis: simdi.add(const Duration(minutes: 15))),
      );
    final servis = OturumServisi(ApiIstemcisi(), depo, simdi: () => simdi);
    await servis.hazirla();
    expect(servis.girisYapildi, isTrue);
    simdi = simdi.add(const Duration(minutes: 15));
    await tester.pump(const Duration(minutes: 15));
    expect(servis.girisYapildi, isFalse);
    expect(depo.veri, isNull);
    servis.dispose();
  });
  test('bozuk veya süresi geçmiş kayıtla oturum açılmaz', () async {
    for (final veri in [
      '{bozuk',
      jsonEncode(oturumYaniti(bitis: DateTime.utc(2020))),
    ]) {
      final depo = BellekDeposu()..veri = veri;
      final servis = OturumServisi(ApiIstemcisi(), depo);
      await servis.hazirla();
      expect(servis.girisYapildi, isFalse);
      expect(depo.veri, isNull);
      servis.dispose();
    }
  });
  test('güvenli depoya yazılamayan giriş başarılı sayılmaz', () async {
    final depo = BellekDeposu()..yazmaHatasi = true;
    final servis = denemeOturumu(depo: depo);
    await expectLater(
      servis.giris('a@b.com', 'Deneme123!'),
      throwsA(isA<ApiHatasi>()),
    );
    expect(servis.girisYapildi, isFalse);
    servis.dispose();
  });
  test('güvenli depolama adaptörü tokenı yazıp okuyup temizler', () async {
    final alan = <String, String>{};
    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final args = Map<String, dynamic>.from(call.arguments as Map);
          switch (call.method) {
            case 'write':
              alan[args['key'] as String] = args['value'] as String;
              return null;
            case 'read':
              return alan[args['key']];
            case 'delete':
              alan.remove(args['key']);
              return null;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final depo = CihazOturumDeposu(saklama: const FlutterSecureStorage());
    await depo.yaz('gizli-test-oturumu');
    expect(await depo.oku(), 'gizli-test-oturumu');
    expect(alan.keys, ['mobil_oturum']);
    await depo.yaz(null);
    expect(await depo.oku(), isNull);
  });
  test(
    'HTTP eğitim servisi sunucunun erişim ve nullable kategori alanlarını korur',
    () async {
      final api = ApiIstemcisi(
        istemci: MockClient(
          (r) async => jsonYanit([
            {
              'id': 9,
              'kategoriId': null,
              'kod': 'ESKI',
              'baslik': 'Ders',
              'misafireAcik': false,
              'erisilebilir': true,
              'ozet': 'Özet',
              'gorevSayisi': 3,
            },
          ]),
        ),
      );
      final ders = (await HttpEgitimServisi(api).egitimleriGetir()).single;
      expect(ders.erisilebilir, isTrue);
      expect(ders.misafireAcik, isFalse);
      expect(ders.gorevSayisi, 3);
      expect(ders.kategoriId, isNull);
    },
  );
}
