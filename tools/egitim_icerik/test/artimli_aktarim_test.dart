import 'dart:convert';
import 'dart:io';
import 'package:egitim_icerik/src/api_yukleyici.dart';
import 'package:egitim_icerik/src/artimli_aktarim.dart';
import 'package:egitim_icerik/src/yukleme_komutu.dart';
import 'package:egitim_icerik/src/yukleme_plani.dart';
import 'package:test/test.dart';
import 'yukleme_test.dart' show SahteApi, plan;
import 'yukleme_v2_test.dart' show v2Veri;

void main() {
  late Directory gecici;
  late ArtimliDurum durum;
  final hedef = Uri.parse('http://localhost:5080/');
  setUp(() {
    gecici = Directory.systemTemp.createTempSync('artimli-');
    Directory('${gecici.path}/kaynak').createSync();
    durum = ArtimliDurum(
      '${gecici.path}/durum.json',
      kaynak: '${gecici.path}/kaynak',
    );
  });
  tearDown(() => gecici.deleteSync(recursive: true));
  Future<bool> aktar(SahteApi api, YuklemePlani paket, {HttpGonder? gonder}) =>
      ArtimliYukleyici(
        IcerikYukleyici(hedef, gonder ?? api.cevap),
        durum,
      ).yukle(
        paket,
        eposta: 'yonetici@example.test',
        sifre: 'test-parolasi',
        yaz: (_) {},
      );

  test('İlk aktarım, değişmemişte sıfır HTTP, değişmiş ve yeni ders', () async {
    final api = SahteApi();
    expect(await aktar(api, plan(sayi: 2)), isTrue);
    expect(api.aktarimSayisi, 2);
    final once = api.istekler.length;
    expect(await aktar(api, plan(sayi: 2)), isTrue);
    expect(api.istekler.length, once);
    final p = plan(sayi: 3);
    p.dersler.first['icerikMarkdown'] = '# Değişen konu';
    expect(await aktar(api, p), isTrue);
    expect(api.aktarimSayisi, 4);
    expect(api.kayitlar['PY-01']!['icerikMarkdown'], '# Değişen konu');
    // Sunucunun korunan kategori değerleri gereksiz yeniden yükleme üretmez.
    expect(await aktar(api, p), isTrue);
    expect(api.aktarimSayisi, 4);
  });

  test(
    'Kısmi başarısızlıkta yalnız başarısız ve bekleyen dersler yeniden denenir',
    () async {
      final api = SahteApi();
      final denemeler = <String>[];
      var hata = true;
      Future<HttpYaniti> gonder(
        String m,
        Uri u,
        Map<String, String> h,
        String? b,
      ) async {
        if (m == 'POST' && u.path == '/api/icerik/aktar') {
          final kod =
              jsonDecode(b!)['kategoriler'][0]['egitimler'][0]['kod'] as String;
          denemeler.add(kod);
          if (hata && kod == 'PY-02') return HttpYaniti(500, '');
        }
        return api.cevap(m, u, h, b);
      }

      expect(await aktar(api, plan(sayi: 3), gonder: gonder), isFalse);
      expect(denemeler, ['PY-01', 'PY-02']);
      durum.oku();
      expect(durum.ayir(plan(sayi: 3), hedef).map((d) => d.durum), [
        'degismemis',
        'yeni',
        'yeni',
      ]);
      hata = false;
      expect(await aktar(api, plan(sayi: 3), gonder: gonder), isTrue);
      expect(denemeler, ['PY-01', 'PY-02', 'PY-02', 'PY-03']);
    },
  );

  test('Başarılı POST fakat bozuk geri okuma güncel işaretlenmez', () async {
    final api = SahteApi()..bozukDers = 'PY-01';
    expect(await aktar(api, plan()), isFalse);
    expect(durum.dosya.existsSync(), isFalse);
    api.bozukDers = null;
    expect(await aktar(api, plan()), isTrue);
    expect(api.aktarimSayisi, 2);
  });

  test(
    'Kaybolan POST yanıtı otomatik tekrar edilmez; sonraki komut tekrar dener',
    () async {
      final api = SahteApi()..kayipYanit = true;
      expect(await aktar(api, plan()), isFalse);
      expect(api.aktarimSayisi, 1);
      expect(durum.dosya.existsSync(), isFalse);
      api.kayipYanit = false;
      expect(await aktar(api, plan()), isTrue);
      expect(api.aktarimSayisi, 2);
    },
  );

  test('Hedefler ayrıdır; kaynaktan kaldırılan ders silinmez', () async {
    final api = SahteApi();
    await aktar(api, plan(sayi: 2));
    durum.oku();
    expect(
      durum.ayir(plan(), Uri.parse('http://localhost:5081/')).single.durum,
      'yeni',
    );
    expect(
      durum
          .ayir(plan(), Uri.parse('http://localhost:5080/diger/'))
          .single
          .durum,
      'yeni',
    );
    expect(
      durum.ayir(plan(), Uri.parse('http://localhost:5080')).single.durum,
      'degismemis',
    );
    await aktar(api, plan());
    expect(api.kayitlar.keys, contains('PY-02'));
    durum.oku();
    expect(durum.ayir(plan(sayi: 2), hedef).last.durum, 'degismemis');
  });

  test(
    'Kararlı özet: nesne/görev/yasak sırası önemsiz; gerçek alanlar anlamlı',
    () {
      final a = <String, dynamic>{
        'surum': 2,
        'gorevler': [
          {
            'no': 2,
            'kontrol': {
              'kullanilmamali': ['b', 'a'],
            },
          },
          {'no': 1, 'baslangicKodu': '  kod\n'},
        ],
      };
      final b = <String, dynamic>{
        'gorevler': [
          {'baslangicKodu': '  kod\n', 'no': 1},
          {
            'kontrol': {
              'kullanilmamali': ['a', 'b'],
            },
            'no': 2,
          },
        ],
        'surum': 2,
      };
      expect(paketOzeti(a), paketOzeti(b));
      for (final alan in [
        'icerikMarkdown',
        'baslangicKodu',
        'testKodu',
        'baslik',
        'sira',
        'gorevler',
        'kontrol',
        'baslangicDosyasi',
      ]) {
        expect(
          paketOzeti({...a, alan: 'değişti'}),
          isNot(paketOzeti(a)),
          reason: alan,
        );
      }
      b['gorevler'][0]['baslangicKodu'] = 'kod\n';
      expect(paketOzeti(a), isNot(paketOzeti(b)));
    },
  );

  test('V2 kontrol ve kod değişimleri seçilir; geçiş onayı korunur', () async {
    final api = SahteApi();
    YuklemePlani yeni() => yuklemePlani(v2Veri(), {'PY-01'}, surum: 2);
    expect(await aktar(api, yeni()), isTrue);
    final degisen = yeni();
    degisen.dersler.single['gorevler'][0]['kontrol']['beklenenCikti'] =
        'Yeni çıktı\n';
    durum.oku();
    expect(durum.ayir(degisen, hedef).single.durum, 'degismis');
    expect(await aktar(api, degisen), isFalse);
    expect(api.aktarimSayisi, 1);
    expect(
      await ArtimliYukleyici(IcerikYukleyici(hedef, api.cevap), durum).yukle(
        degisen,
        eposta: 'yonetici@example.test',
        sifre: 'test-parolasi',
        yaz: (_) {},
        v2GecisOnayi: true,
      ),
      isTrue,
    );
    expect(api.aktarimSayisi, 2);
    durum.oku();
    expect(durum.ayir(degisen, hedef).single.durum, 'degismemis');
    degisen.dersler.single['gorevler'][0]['baslangicKodu'] += '# yeni\n';
    expect(durum.ayir(degisen, hedef).single.durum, 'degismis');
  });
  test('Bozuk durum kaydı korunur; yükleme yapılmaz', () async {
    durum.dosya.writeAsStringSync('{"semaSurumu":99}');
    final api = SahteApi();
    await expectLater(aktar(api, plan()), throwsA(isA<YuklemeHatasi>()));
    expect(api.istekler, isEmpty);
    expect(durum.dosya.readAsStringSync(), '{"semaSurumu":99}');
  });

  test(
    'Tam aktarım hâlâ tek POST ile bütün seçili dersleri gönderir',
    () async {
      final api = SahteApi();
      final sonuc = await IcerikYukleyici(hedef, api.cevap).yukle(
        plan(sayi: 2),
        eposta: 'yonetici@example.test',
        sifre: 'test-parolasi',
      );
      expect(sonuc.basarili, isTrue);
      expect(api.aktarimSayisi, 1);
      expect(api.kayitlar.length, 2);
      expect(durum.dosya.existsSync(), isFalse);
    },
  );

  test(
    'CLI dry-run sıfır HTTP; durum/kilit/üst klasör oluşturmaz veya değiştirmez',
    () async {
      final ders = Directory('${gecici.path}/kaynak/dersler/PY-01')
        ..createSync(recursive: true);
      File('${ders.path}/README.md').writeAsStringSync('# Konu\nMerhaba');
      File(
        '${ders.path}/ALISTIRMALAR.md',
      ).writeAsStringSync('# Alıştırmalar\n## Görev 1 — Bir\nAçıkla.');
      final yol = '${gecici.path}/yeni/durum.json';
      final cikti = <String>[];
      final args = [
        '--kaynak',
        '${gecici.path}/kaynak',
        '--api',
        hedef.toString(),
        '--ders',
        'PY-01',
        '--artimli',
        '--dry-run',
        '--durum-dosyasi',
        yol,
        '--kismi-aktarimi-onayla',
      ];
      var istek = 0;
      Future<HttpYaniti> gonder(
        String m,
        Uri u,
        Map<String, String> h,
        String? b,
      ) async {
        istek++;
        throw StateError('HTTP olmamalı');
      }

      expect(
        await yuklemeKomutu(args, gonder: gonder, yaz: cikti.add),
        0,
        reason: cikti.join('\n'),
      );
      expect(istek, 0);
      expect(Directory('${gecici.path}/yeni').existsSync(), isFalse);
      expect(cikti.any((s) => s.contains('YÜKLENECEK PY-01')), isTrue);
      // Geçerli mevcut durum da dry-run sırasında değişmez.
      await aktar(SahteApi(), plan());
      final once = durum.dosya.readAsBytesSync();
      args[args.indexOf(yol)] = durum.dosya.path;
      expect(await yuklemeKomutu(args, gonder: gonder, yaz: (_) {}), 0);
      expect(durum.dosya.readAsBytesSync(), once);
      expect(istek, 0);
    },
  );
}
