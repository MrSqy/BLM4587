import 'dart:convert';
import 'dart:io';
import 'package:egitim_icerik/egitim_icerik.dart';
import 'package:egitim_icerik/src/api_yukleyici.dart';
import 'package:egitim_icerik/src/yukleme_plani.dart';
import 'package:egitim_icerik/src/yukleme_komutu.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Map<String, dynamic> ornek({int sayi = 1, bool kodBos = false}) => {
  'kategoriler': [
    {'id': 99, 'kisaltma': 'PY', 'ad': 'Python', 'sira': 1},
  ],
  'egitimler': List.generate(
    sayi,
    (i) => <String, dynamic>{
      'id': 999 + i,
      'kategoriId': 99,
      'kod': 'PY-0${i + 1}',
      'baslik': 'Türkçe ders ${i + 1}',
      'sira': i + 1,
      'icerikMarkdown': '# Alıştırmalar\nÇağla',
      'baslangicKodu': kodBos ? '' : '# başlangıç',
      'testKodu': kodBos ? '' : '# gerçek kaynak testi',
      'gorevler': [
        {
          'id': 888,
          'egitimId': 999 + i,
          'no': 1,
          'baslik': 'Görev',
          'aciklama': 'Açıklama',
        },
      ],
    },
  ),
  'uyarilar': <String>[],
};
YuklemePlani plan({int sayi = 1, bool kodBos = false}) => yuklemePlani(
  ornek(sayi: sayi, kodBos: kodBos),
  Set.from(List.generate(sayi, (i) => 'PY-0${i + 1}')),
  surum: 1,
);

class SahteApi {
  final kayitlar = <String, Map<String, dynamic>>{};
  final istekler = <String>[];
  int csrfDurum = 200, aktarDurum = 200;
  bool bozukGiris = false, kayipYanit = false, jwtGerekli = false;
  bool v2Destegi = true, bozukKontrol = false;
  final pasifGorevler = <String, List<Map<String, dynamic>>>{};
  String? bozukDers;
  Map<String, dynamic>? sonPaket;
  int get aktarimSayisi =>
      istekler.where((s) => s == 'POST /api/icerik/aktar').length;
  Future<HttpYaniti> cevap(
    String metot,
    Uri uri,
    Map<String, String> basliklar,
    String? govde,
  ) async {
    final yol = uri.path;
    istekler.add('$metot $yol');
    HttpYaniti json(dynamic v, {int durum = 200}) =>
        HttpYaniti(durum, jsonEncode(v));
    if (yol == '/swagger/v1/swagger.json') {
      return json({
        'components': {
          'schemas': {
            'IcerikPaketi': {
              'properties': {
                'surum': {'maximum': v2Destegi ? 2 : 1},
              },
            },
            'GorevAktarimi': {
              'properties': {
                for (final k in [
                  'tur',
                  'baslangicDosyasi',
                  'baslangicKodu',
                  'kontrol',
                ])
                  k: {},
              },
            },
            'GorevKontrolu': {
              'properties': {
                for (final k in [
                  'tur',
                  'beklenenCikti',
                  'girdi',
                  'beklenenCikisKodu',
                  'kullanilmamali',
                ])
                  k: {},
              },
            },
          },
        },
        'paths': {
          if (v2Destegi) '/api/mobil/egitimler/{id}/gorevler/{no}/test': {},
        },
      });
    }
    if (yol == '/api/egitimler') {
      final liste = kayitlar.values
          .where((d) => d['kod'] == uri.queryParameters['q'])
          .map((d) => {'id': d['id'], 'kategoriId': 42, 'kod': d['kod']})
          .toList();
      return json({'toplam': liste.length, 'egitimler': liste});
    }
    if (yol == '/api/mobil/kategoriler') {
      return json([
        {
          'id': 42,
          'kisaltma': 'PY',
          'ad': 'Mevcut kategori',
          'aciklama': 'Koru',
          'sira': 3,
        },
      ]);
    }
    if (yol == '/Hesap/Giris' && metot == 'GET') {
      return HttpYaniti(
        200,
        '<input value="form-token" type="hidden" name="__RequestVerificationToken">',
      );
    }
    if (yol == '/Hesap/Giris' && metot == 'POST') {
      final form = Uri.splitQueryString(govde!);
      expect(form['Input.Eposta'], 'yonetici@example.test');
      expect(form['Input.Sifre'], 'test-parolasi');
      expect(form['__RequestVerificationToken'], 'form-token');
      return HttpYaniti(bozukGiris ? 200 : 302, 'hassas sunucu metni');
    }
    if (yol == '/api/hesap/giris') {
      return json({'accessToken': 'test-jwt', 'tokenType': 'Bearer'});
    }
    if (yol == '/api/icerik/antiforgery') {
      return json({'token': 'csrf-token'}, durum: csrfDurum);
    }
    if (yol == '/api/icerik/aktar') {
      expect(basliklar['X-CSRF-TOKEN'], 'csrf-token');
      sonPaket = jsonDecode(govde!) as Map<String, dynamic>;
      if (aktarDurum != 200) {
        return HttpYaniti(aktarDurum, 'test-parolasi csrf-token');
      }
      var gorev = 0;
      var dersSayisi = 0;
      for (final dynamic k in sonPaket!['kategoriler']) {
        for (final dynamic d in k['egitimler']) {
          final kod = d['kod'] as String;
          final id = kayitlar[kod]?['id'] ?? 700 + kayitlar.length;
          final onceki = (kayitlar[kod]?['gorevler'] as List? ?? [])
              .cast<Map<String, dynamic>>();
          if (sonPaket!['surum'] == 2) {
            pasifGorevler[kod] = [
              ...?pasifGorevler[kod],
              ...onceki
                  .where(
                    (g) => !(d['gorevler'] as List).any(
                      (dynamic yeni) => yeni['no'] == g['no'],
                    ),
                  )
                  .map((g) => {...g, 'aktif': false}),
            ];
          }
          dersSayisi++;
          kayitlar[kod] = {
            ...d as Map<String, dynamic>,
            'id': id,
            'kategoriId': 42,
            'gorevler': (d['gorevler'] as List)
                .map(
                  (dynamic g) => {
                    ...g as Map<String, dynamic>,
                    'id':
                        onceki
                            .where((gorev) => gorev['no'] == g['no'])
                            .firstOrNull?['id'] ??
                        5000 + (id as int) * 100 + (g['no'] as int),
                    'egitimId': id,
                  },
                )
                .toList(),
          };
          gorev += (d['gorevler'] as List).length;
        }
      }
      if (kayipYanit) {
        throw YuklemeHatasi('Zaman aşımı; kayıt sonucu belirsiz.');
      }
      return json({
        'kategoriSayisi': 1,
        'egitimSayisi': dersSayisi,
        'gorevSayisi': gorev,
      });
    }
    if (yol.startsWith('/api/mobil/egitimler/')) {
      if (jwtGerekli && basliklar['Authorization'] != 'Bearer test-jwt') {
        return HttpYaniti(401, '');
      }
      final id = int.parse(yol.split('/').last);
      final ders = kayitlar.values.singleWhere((d) => d['id'] == id);
      final sonuc = {...ders, if (ders['kod'] == bozukDers) 'baslik': 'bozuk'};
      if (bozukKontrol && sonuc['gorevler'] is List) {
        sonuc['gorevler'] = (sonuc['gorevler'] as List)
            .map((dynamic g) => {...g as Map<String, dynamic>, 'kontrol': null})
            .toList();
      }
      return json(sonuc);
    }
    throw StateError('Beklenmeyen mock isteği: $metot $yol');
  }
}

Future<YuklemeSonucu> calistir(
  SahteApi api,
  YuklemePlani p, {
  bool onay = false,
}) => IcerikYukleyici(Uri.parse('http://localhost/'), api.cevap).yukle(
  p,
  eposta: 'yonetici@example.test',
  sifre: 'test-parolasi',
  kayipOnayi: onay,
);

void main() {
  test(
    'DTO iç içedir; geçici kimlikler gönderilmez, kategori bilgileri korunur',
    () async {
      final api = SahteApi();
      final sonuc = await calistir(api, plan());
      expect(sonuc.basarili, isTrue);
      expect(sonuc.dogrulanan, ['PY-01']);
      expect(api.kayitlar['PY-01']!['id'], 700);
      final k = (api.sonPaket!['kategoriler'] as List).single;
      expect(k['ad'], 'Mevcut kategori');
      expect(k['aciklama'], 'Koru');
      final d = (k['egitimler'] as List).single;
      expect(d.containsKey('id'), isFalse);
      expect(d.containsKey('kategoriId'), isFalse);
      expect(d['gorevler'][0].containsKey('egitimId'), isFalse);
      expect(d['gorevler'][0].containsKey('id'), isFalse);
    },
  );
  test('Tekrar aktarım aynı sunucu kimliğini kullanır; kopya yok', () async {
    final api = SahteApi();
    expect((await calistir(api, plan())).basarili, isTrue);
    final id = api.kayitlar['PY-01']!['id'];
    expect((await calistir(api, plan())).basarili, isTrue);
    expect(api.kayitlar, hasLength(1));
    expect(api.kayitlar['PY-01']!['id'], id);
  });
  test('401/403 yönetici hataları aktarım isteği göndermez', () async {
    for (final durum in [401, 403]) {
      final api = SahteApi()..csrfDurum = durum;
      final sonuc = await calistir(api, plan());
      expect(sonuc.basarili, isFalse);
      expect(sonuc.hata, contains('$durum'));
      expect(api.aktarimSayisi, 0);
    }
  });
  test(
    'Hatalı giriş ve sunucu doğrulama/çakışma hatası anlaşılır; sırlar yok',
    () async {
      final api = SahteApi()..bozukGiris = true;
      expect((await calistir(api, plan())).hata, contains('Giriş başarısız'));
      for (final durum in [400, 409, 413, 429, 500]) {
        final api = SahteApi()..aktarDurum = durum;
        final sonuc = await calistir(api, plan());
        expect(sonuc.hata, contains('$durum'));
        expect(sonuc.hata, isNot(contains('test-parolasi')));
        expect(sonuc.kayitOnaylandi, isFalse);
        expect(api.aktarimSayisi, 1);
      }
    },
  );
  test(
    'Paket kaydedildi ancak ikinci ders geri okuması başarısızsa kısmi doğrulama',
    () async {
      final api = SahteApi()..bozukDers = 'PY-02';
      final sonuc = await calistir(api, plan(sayi: 2));
      expect(sonuc.kayitOnaylandi, isTrue);
      expect(sonuc.basarili, isFalse);
      expect(sonuc.dogrulanan, ['PY-01']);
      expect(sonuc.bekleyen, ['PY-02']);
      expect(api.aktarimSayisi, 1);
    },
  );
  test('Yazma yanıtı kaybolursa POST otomatik tekrarlanmaz', () async {
    final api = SahteApi()..kayipYanit = true;
    final sonuc = await calistir(api, plan());
    expect(sonuc.hata, contains('belirsiz'));
    expect(api.aktarimSayisi, 1);
    expect(sonuc.dogrulanan, isEmpty);
  });
  test(
    'Mevcut dersin boş kod/test ile güncellenmesi onaya rağmen durdurulur',
    () async {
      final api = SahteApi();
      await calistir(api, plan());
      final sonuc = await calistir(api, plan(kodBos: true), onay: true);
      expect(sonuc.hata, contains('mevcut veriyi silebilir'));
      expect(api.aktarimSayisi, 1); // Yalnız ilk, dolu kodlu aktarım.
      expect(api.kayitlar['PY-01']!['testKodu'], '# gerçek kaynak testi');
    },
  );
  test(
    'Kaynak alanı kaybı varsayılan olarak sıfır HTTP ile engellenir',
    () async {
      final p = plan()..kayiplar.add('kontrol');
      final api = SahteApi();
      final sonuc = await calistir(api, p);
      expect(sonuc.basarili, isFalse);
      expect(api.istekler, isEmpty);
      expect((await calistir(api, p, onay: true)).basarili, isTrue);
    },
  );
  test(
    'Korunan detay JWT ile geri okunur; aktarım POST tekrar edilmez',
    () async {
      final api = SahteApi()..jwtGerekli = true;
      expect((await calistir(api, plan())).basarili, isTrue);
      expect(api.istekler, contains('POST /api/hesap/giris'));
      expect(api.aktarimSayisi, 1);
    },
  );
  test('Yerel DTO limitleri, ilişki, görev tekrarları ve URL doğrulaması', () {
    final v = ornek();
    v['egitimler'][0]['baslik'] = 'x' * 151;
    expect(() => yuklemePlani(v, {'PY-01'}), throwsA(isA<YuklemeHatasi>()));
    final g = ornek();
    g['egitimler'][0]['gorevler'].add(g['egitimler'][0]['gorevler'][0]);
    expect(() => yuklemePlani(g, {'PY-01'}), throwsA(isA<YuklemeHatasi>()));
    expect(
      () => yuklemePlani(ornek(), {'PY-99'}),
      throwsA(isA<YuklemeHatasi>()),
    );
    expect(
      () => apiAdresi('http://user:password@localhost/'),
      throwsA(isA<YuklemeHatasi>()),
    );
    expect(() => apiAdresi('file:///tmp'), throwsA(isA<YuklemeHatasi>()));
  });
  test(
    'Dry-run kişisel yol ve canlı API kullanmadan seçilen ders için sıfır HTTP üretir',
    () async {
      final dizin = Directory.systemTemp.createTempSync('yukleme_');
      try {
        void yaz(String yol, String metin) {
          final f = File(p.join(dizin.path, yol));
          f.parent.createSync(recursive: true);
          f.writeAsStringSync(metin);
        }

        yaz('dersler/PY-01/README.md', '# PY-01 — Bir');
        yaz('dersler/PY-01/LAB.md', '# Ek laboratuvar');
        yaz('dersler/PY-01/ALISTIRMALAR.md', '## Görev 1 — Bir\nAçıkla.');
        yaz(
          'dersler/PY-02/README.md',
          'Bozuk ders; seçilmediği için okunmamalı.',
        );
        final mesajlar = <String>[];
        var istek = 0;
        Future<HttpYaniti> http(
          String m,
          Uri u,
          Map<String, String> h,
          String? b,
        ) async {
          istek++;
          throw StateError('Ağ kullanılmamalı');
        }

        final args = [
          '--kaynak',
          dizin.path,
          '--api',
          'http://localhost:1234',
          '--ders',
          'PY-01',
          '--dry-run',
        ];
        expect(await yuklemeKomutu(args, gonder: http, yaz: mesajlar.add), 2);
        expect(
          await yuklemeKomutu(
            [...args, '--kismi-aktarimi-onayla'],
            gonder: http,
            yaz: mesajlar.add,
          ),
          0,
        );
        expect(istek, 0);
        expect(mesajlar.join(), contains('Dışarıda kalacak'));
        expect(
          egitimleriAktar(dizin.path, dersKodlari: {'PY-01'})['egitimler'],
          hasLength(1),
        );
        expect(
          await yuklemeKomutu(['--api', 'http://localhost'], yaz: mesajlar.add),
          1,
        );
      } finally {
        dizin.deleteSync(recursive: true);
      }
    },
  );
  test(
    'Gerçek HTTP taşıyıcısı çerezleri tutar ve yönlendirmeyi izlemez',
    () async {
      final sunucu = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var istek = 0;
      final abone = sunucu.listen((r) async {
        istek++;
        if (r.uri.path == '/bir') {
          r.response.cookies.add(Cookie('oturum', 'test')..path = '/');
          r.response.statusCode = 302;
          r.response.headers.set('location', '/izleme');
        } else {
          expect(
            r.cookies.any((c) => c.name == 'oturum' && c.value == 'test'),
            isTrue,
          );
          r.response.write('{}');
        }
        await r.response.close();
      });
      final bag = ApiBaglantisi();
      try {
        final kok = Uri.parse('http://127.0.0.1:${sunucu.port}/');
        expect(
          (await bag.gonder('GET', kok.resolve('bir'), {}, null)).durum,
          302,
        );
        expect(istek, 1);
        expect(
          (await bag.gonder('GET', kok.resolve('iki'), {}, null)).durum,
          200,
        );
      } finally {
        bag.kapat();
        await abone.cancel();
        await sunucu.close(force: true);
      }
    },
  );
  test('Gerçek HTTP taşıyıcısının zaman aşımı ve bağlantı hatası', () async {
    final sunucu = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final abone = sunucu.listen((r) {});
    final kok = Uri.parse('http://127.0.0.1:${sunucu.port}/');
    final bag = ApiBaglantisi(zamanAsimi: const Duration(milliseconds: 30));
    try {
      await expectLater(
        bag.gonder('GET', kok, {}, null),
        throwsA(
          isA<YuklemeHatasi>().having(
            (e) => e.mesaj,
            'mesaj',
            contains('Zaman aşımı'),
          ),
        ),
      );
    } finally {
      bag.kapat();
      await abone.cancel();
      await sunucu.close(force: true);
    }
    final kapali = ApiBaglantisi();
    try {
      await expectLater(
        kapali.gonder('GET', kok, {}, null),
        throwsA(isA<YuklemeHatasi>()),
      );
    } finally {
      kapali.kapat();
    }
  });
}
