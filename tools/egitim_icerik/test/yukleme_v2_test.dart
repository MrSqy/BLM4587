import 'dart:convert';
import 'package:egitim_icerik/src/api_yukleyici.dart';
import 'package:egitim_icerik/src/yukleme_plani.dart';
import 'package:test/test.dart';
import 'yukleme_test.dart' show SahteApi;

Map<String, dynamic> v2Veri() {
  final dosyalar = <String, dynamic>{};
  final gorevler = List.generate(7, (i) {
    final no = i + 1;
    final dosya = no <= 5 ? 'gorevler/gorev_$no.py' : null;
    final kod = dosya == null
        ? ''
        : no == 4
        ? 'print("bozuk)\n'
        : '# Görev $no başlangıcı\n';
    if (dosya != null) dosyalar[dosya] = {'kodlama': 'utf-8', 'icerik': kod};
    return <String, dynamic>{
      'id': 900 + no,
      'egitimId': 999,
      'no': no,
      'baslik': 'Görev $no',
      'aciklama': 'Açıklama $no',
      'baslangicDosyasi': dosya,
      'baslangicKodu': kod,
      'testler': <dynamic>[],
      'kontrol': dosya == null
          ? null
          : <String, dynamic>{
              'tur': 'standart-cikti',
              'beklenenCikti': '  Çıktı $no\n',
              'girdi': 'Ada\n',
              'beklenenCikisKodu': 0,
              'kullanilmamali': <String>[],
            },
    };
  });
  return {
    'kategoriler': [
      {'id': 99, 'ad': 'Python', 'kisaltma': 'PY', 'sira': 1},
    ],
    'egitimler': [
      {
        'id': 999,
        'kategoriId': 99,
        'kod': 'PY-01',
        'baslik': 'İlk Python programı',
        'sira': 1,
        'icerikMarkdown': '# Görevler',
        'baslangicKodu': '',
        'testKodu': '',
        'gorevler': gorevler,
        'kaynakDosyalari': dosyalar,
        'testler': <dynamic>[],
      },
    ],
    'uyarilar': <String>[],
  };
}

Map<String, dynamic> ders(Map<String, dynamic> veri) =>
    (veri['egitimler'] as List).single as Map<String, dynamic>;
Future<YuklemeSonucu> aktar(
  SahteApi api,
  YuklemePlani plan, {
  bool gecis = false,
  bool onay = false,
}) => IcerikYukleyici(Uri.parse('http://localhost/'), api.cevap).yukle(
  plan,
  eposta: 'yonetici@example.test',
  sifre: 'test-parolasi',
  v2GecisOnayi: gecis,
  kayipOnayi: onay,
);

void main() {
  test(
    'V2 5 kod + 2 açıklama: görev kodları/kontrolleri kayıpsız, geçici ID yok',
    () {
      final p = yuklemePlani(v2Veri(), {'PY-01'});
      expect(p.paket['surum'], 2);
      expect(p.kayiplar, isEmpty);
      final d = p.dersler.single;
      final g = d['gorevler'] as List;
      expect(g.where((dynamic v) => v['tur'] == 'kod'), hasLength(5));
      expect(g.where((dynamic v) => v['tur'] == 'aciklama'), hasLength(2));
      expect(g[0]['kontrol']['beklenenCikti'], '  Çıktı 1\n');
      expect(g[0]['kontrol']['girdi'], 'Ada\n');
      expect(
        g[3]['baslangicKodu'],
        'print("bozuk)\n',
      ); // Python çalıştırılmaz/düzeltilmez.
      expect(g[6]['kontrol'], isNull);
      expect(g[6]['baslangicDosyasi'], isNull);
      expect(g[0].containsKey('id'), isFalse);
      expect(g[0].containsKey('egitimId'), isFalse);
    },
  );
  test(
    'V2 gerçek kaynak eşliği, türler, kontrol alanları ve sınırlar doğrulanır',
    () {
      final degistiriciler = <void Function(Map<String, dynamic>)>[
        (v) => ders(v)['gorevler'][0]['kontrol'] = null,
        (v) => ders(v)['gorevler'][0]['kontrol']['beklenenCikti'] = null,
        (v) => ders(v)['gorevler'][0]['kontrol']['beklenenCikti'] = 'x' * 64001,
        (v) => ders(v)['gorevler'][0]['kontrol']['girdi'] = 'x' * 32001,
        (v) => ders(v)['gorevler'][0]['kontrol']['beklenenCikisKodu'] = 256,
        (v) =>
            ders(v)['gorevler'][0]['kontrol']['kullanilmamali'] = ['yasak\n'],
        (v) => ders(v)['gorevler'][0]['kontrol']['kullanilmamali'] =
            List.filled(31, 'ad'),
        (v) =>
            ders(v)['gorevler'][0]['baslangicDosyasi'] = 'gorevler/../gizli.py',
        (v) =>
            ders(v)['gorevler'][1]['baslangicDosyasi'] = 'gorevler/gorev_1.py',
        (v) => ders(v)['gorevler'][0]['baslangicKodu'] = 'farklı',
        (v) =>
            (ders(v)['kaynakDosyalari'] as Map).remove('gorevler/gorev_1.py'),
        (v) => ders(v)['gorevler'][5]['baslangicKodu'] = 'açıklamaya kod olmaz',
        (v) => ders(v)['gorevler'] = <dynamic>[],
        (v) => ders(v)['testKodu'] = 'import pytest',
      ];
      for (final degistir in degistiriciler) {
        final v = v2Veri();
        degistir(v);
        expect(() => yuklemePlani(v, {'PY-01'}), throwsA(isA<YuklemeHatasi>()));
      }
    },
  );
  test(
    'Ek modül ve veri dosyaları v2 ile eksiksiz çalışır gibi gösterilmez',
    () {
      for (final yol in [
        'gorevler/yardimci.py',
        'veri/notlar.txt',
        'proje/pyproject.toml',
      ]) {
        final v = v2Veri();
        ders(v)['kaynakDosyalari'][yol] = {
          'kodlama': 'utf-8',
          'icerik': 'örnek',
        };
        expect(
          () => yuklemePlani(v, {'PY-01'}),
          throwsA(
            isA<YuklemeHatasi>().having(
              (e) => e.mesaj,
              'mesaj',
              contains('ek modül/veri'),
            ),
          ),
        );
      }
    },
  );
  test(
    'Arşiv eksikleri açık kalır; taşınan görev kodları artık kayıp sayılmaz',
    () {
      final v = v2Veri();
      ders(v)['kaynakDosyalari']['ornek.py'] = {
        'kodlama': 'utf-8',
        'icerik': '# örnek',
      };
      ders(v)['markdownDosyalari'] = {
        'README.md': '# Anlatım',
        'ALISTIRMALAR.md': '# Görevler',
      };
      v['ortakDosyalar'] = {'kontrol/kontrol.py': '# kaynak denetleyici'};
      final p = yuklemePlani(v, {'PY-01'});
      expect(p.kayiplar, hasLength(3));
      expect(p.kayiplar.join(), isNot(contains('baslangicKodu ayrı alan')));
    },
  );
  test(
    'Eski çalışan sunucuya v2 gönderilmez; geçiş onayı bunu aşamaz',
    () async {
      final api = SahteApi()..v2Destegi = false;
      final r = await aktar(
        api,
        yuklemePlani(v2Veri(), {'PY-01'}),
        gecis: true,
      );
      expect(r.basarili, isFalse);
      expect(r.hata, contains('v2 sözleşmesi doğrulanamadı'));
      expect(api.istekler.any((s) => s.startsWith('POST')), isFalse);
    },
  );
  test(
    'Mevcut ders açık onay olmadan korunur; v2 geçişi görev 8’i silmeden pasifleştirir',
    () async {
      final api = SahteApi();
      api.kayitlar['PY-01'] = {
        'id': 41,
        'kategoriId': 42,
        'kod': 'PY-01',
        'baslangicKodu': 'eski kod',
        'testKodu': 'eski test',
        'gorevler': List.generate(
          8,
          (i) => <String, dynamic>{
            'id': 100 + i,
            'egitimId': 41,
            'no': i + 1,
            'baslik': 'Eski ${i + 1}',
            'aciklama': 'Eski açıklama',
            'tur': 'eski-pytest',
          },
        ),
      };
      final p = yuklemePlani(v2Veri(), {'PY-01'});
      expect(
        (await aktar(api, p, onay: true)).hata,
        contains('--v2-gecisini-onayla'),
      );
      expect(api.aktarimSayisi, 0);
      expect(api.kayitlar['PY-01']!['testKodu'], 'eski test');
      final r = await aktar(api, p, gecis: true);
      expect(r.basarili, isTrue);
      expect(api.kayitlar['PY-01']!['id'], 41);
      expect(api.kayitlar['PY-01']!['gorevler'], hasLength(7));
      expect(api.kayitlar['PY-01']!['gorevler'][0]['id'], 100);
      expect(api.pasifGorevler['PY-01']!.single['no'], 8);
      expect(api.pasifGorevler['PY-01']!.single['id'], 107);
      expect(api.pasifGorevler['PY-01']!.single['aktif'], isFalse);
      expect((await aktar(api, p, gecis: true)).basarili, isTrue);
      expect(api.kayitlar, hasLength(1));
      expect(api.pasifGorevler['PY-01'], hasLength(1));
    },
  );
  test(
    'V2 geri okuması kod ve kontrolü de doğrular; yalnız metin eşliği yetmez',
    () async {
      final api = SahteApi()..bozukKontrol = true;
      final r = await aktar(api, yuklemePlani(v2Veri(), {'PY-01'}));
      expect(r.kayitOnaylandi, isTrue);
      expect(r.basarili, isFalse);
      expect(r.hata, contains('v2 kontrol'));
      expect(api.aktarimSayisi, 1);
    },
  );
  test('V2 görev türü ve kontrol alanları JSON turunda korunur', () {
    final p = yuklemePlani(v2Veri(), {'PY-01'});
    final tekrar = jsonDecode(jsonEncode(p.paket)) as Map;
    final g = tekrar['kategoriler'][0]['egitimler'][0]['gorevler'];
    expect(g[0]['tur'], 'kod');
    expect(g[5]['tur'], 'aciklama');
    expect(g[0]['kontrol']['girdi'], 'Ada\n');
  });
}
