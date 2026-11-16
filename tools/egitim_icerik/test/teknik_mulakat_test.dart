import 'dart:convert';
import 'dart:io';
import 'package:egitim_icerik/egitim_icerik.dart';
import 'package:egitim_icerik/src/api_yukleyici.dart';
import 'package:egitim_icerik/src/yukleme_komutu.dart';
import 'package:egitim_icerik/src/yukleme_plani.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'yukleme_test.dart' show SahteApi;

/// Sentetik fixture: gerçek eğitim klasörüne veya kişisel yollara bağımlı değil.
class DemoKaynak {
  final Directory kok = Directory.systemTemp.createTempSync('tm_kaynak_');
  late Map<String, dynamic> paket;
  static const kod = '# TODO: Çözümü öğrenci yazacak.\nprint(0)\n';
  static const konu =
      'Türkçe konu ve `kod`.\n\n```python\n# Kod başlığı\nprint("örnek")\n```';
  static const gorev =
      '## Görev 1 — Say\n\n**Dosya:** `gorevler/say.py`\n\nSay.\n\n**Girdi:**\n\n```text\n2\n   \nÇağla\n```\n\n**Beklenen çıktı:**\n\n```text\n1\n```';

  DemoKaynak() {
    final dersler = <Map<String, dynamic>>[];
    for (final (ad, sira) in [('TM-DEMO-00', 2), ('TM-DEMO-27', 1)]) {
      yaz(
        'dersler/$ad/README.md',
        '# Başlık $ad\n\n$konu\n\n[Alıştırmalar](ALISTIRMALAR.md)\n',
      );
      yaz(
        'dersler/$ad/ALISTIRMALAR.md',
        '# Alıştırmalar\n\n$gorev\n\n## Görev 2 — Açıkla\n\nNeden?\n\n<details>\n<summary>Kendini kontrol et</summary>\nKaynak öz değerlendirme notu.\n</details>\n',
      );
      yaz('dersler/$ad/gorevler/say.py', kod);
      dersler.add({
        'kod': ad,
        'baslik': 'Başlık $ad',
        'sira': sira,
        'icerikMarkdown': konu,
        'baslangicKodu': '',
        'testKodu': '',
        'gorevler': [
          {
            'no': 1,
            'baslik': 'Say',
            'aciklama': 'Say.',
            'tur': 'kod',
            'baslangicDosyasi': 'gorevler/say.py',
            'baslangicKodu': kod,
            'kontrol': {
              'tur': 'standart-cikti',
              'beklenenCikti': '1\n',
              'girdi': '2\n   \nÇağla\n',
              'beklenenCikisKodu': 0,
              'kullanilmamali': <String>[],
            },
          },
          {
            'no': 2,
            'baslik': 'Açıkla',
            'aciklama': 'Neden? Otomatik değerlendirilmez.',
            'tur': 'aciklama',
            'baslangicDosyasi': null,
            'baslangicKodu': '',
            'kontrol': null,
          },
        ],
      });
    }
    paket = {
      'surum': 2,
      'kategoriler': [
        {
          'kisaltma': 'TM-DEMO',
          'ad': 'Teknik Mülakatlar',
          'aciklama': 'Demo eğitim',
          'sira': 50,
          'egitimler': dersler,
        },
      ],
    };
    yaz('kontrol.py', '# Yerel yardımcı; çalıştırılmaz.\n');
    yaz('README.md', '# Yerel kullanım');
    yaz('NOTICE.md', 'Kaynak bildirimi');
    yaz('LICENSE', 'Metin lisansı');
    yaz('LICENSE-CODE', 'Kod lisansı');
    kaydet();
  }
  List<Map<String, dynamic>> get dersler =>
      (paket['kategoriler'][0]['egitimler'] as List)
          .cast<Map<String, dynamic>>();
  void yaz(String yol, String metin) {
    final f = File(p.join(kok.path, p.fromUri(yol)));
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(metin, encoding: utf8);
  }

  void kaydet() => yaz('teknik-mulakat-v2.json', jsonEncode(paket));
  Map<String, dynamic> oku({Set<String>? kodlar}) =>
      egitimleriAktar(kok.path, dersKodlari: kodlar);
  YuklemePlani plan() => yuklemePlani(oku(), {'TM-DEMO-00', 'TM-DEMO-27'});
}

void main() {
  late DemoKaynak f;
  setUp(() => f = DemoKaynak());
  tearDown(() => f.kok.deleteSync(recursive: true));

  test('Kategori ve sıralama manifestten; PY ile ayrı geçici kimlikler', () {
    expect(dersKlasorleriniBul(f.kok.path).map((d) => p.basename(d.path)), [
      'TM-DEMO-27',
      'TM-DEMO-00',
    ]);
    final veri = f.oku();
    final d = (veri['egitimler'] as List).cast<Map<String, dynamic>>();
    expect(veri['kategoriler'][0], containsPair('kisaltma', 'TM-DEMO'));
    expect(veri['kategoriler'][0]['id'], 2);
    expect(veri['kategoriler'][0]['sira'], 50);
    expect(d.map((v) => v['id']), [1000001, 1000002]);
    expect(d.map((v) => v['sira']), [1, 2]);
    expect(d.every((v) => v['kategoriId'] == 2), isTrue);
    final secilen = f.oku(kodlar: {'TM-DEMO-00'});
    expect(secilen['egitimler'].single['id'], 1000002);
    expect(() => f.oku(kodlar: {'PY-01'}), throwsFormatException);
  });

  test(
    'Konu + alıştırmalar, kod blokları ve kontroller kayıpsız; cevap dosyaları dışlanır',
    () {
      f.yaz('dersler/TM-DEMO-00/cozumler/cevap.py', 'GIZLI_COZUM');
      f.yaz('dersler/TM-DEMO-00/ic/solutions/cevap.md', 'GIZLI_COZUM');
      f.yaz('dersler/TM-DEMO-00/referans.py', 'GIZLI_COZUM');
      f.yaz('dersler/TM-DEMO-00/CEVAPLAR.md', 'GIZLI_COZUM');
      final veri = f.oku();
      final d = veri['egitimler'][1];
      expect(d['icerikMarkdown'], contains('## Konu anlatımı'));
      expect(d['icerikMarkdown'], contains('## Alıştırmalar'));
      expect(
        d['icerikMarkdown'],
        contains('```python\n# Kod başlığı\nprint("örnek")\n```'),
      );
      expect(
        d['icerikMarkdown'],
        contains('[Alıştırmalar](#al%C4%B1%C5%9Ft%C4%B1rmalar)'),
      );
      expect(d['icerikMarkdown'], contains('Kaynak öz değerlendirme notu.'));
      expect(d['gorevler'][0]['baslangicKodu'], DemoKaynak.kod);
      expect(d['gorevler'][0]['kontrol']['girdi'], '2\n   \nÇağla\n');
      expect(d['gorevler'][1]['aciklama'], contains('Kaynak paket açıklaması'));
      expect(jsonEncode(veri), isNot(contains('GIZLI_COZUM')));
      final plan = f.plan();
      expect(
        plan.paket['kategoriler'][0]['egitimler'][0]['gorevler'][0]['kontrol'],
        f.dersler[0]['gorevler'][0]['kontrol'],
      );
      expect(plan.kayiplar.join(), contains('kontrol'));
      expect(plan.kayiplar.join(), contains('NOTICE.md'));
      expect(plan.kayiplar.join(), isNot(contains('ALISTIRMALAR.md')));
      expect(plan.dersler.first.containsKey('id'), isFalse);
    },
  );

  test('Kararlı UTF-8 JSON üretimi ve kaynak içine yazma koruması', () {
    final veri = f.oku();
    expect(jsonEncode(f.oku()), jsonEncode(veri));
    final hedef = File(
      p.join(Directory.systemTemp.path, '${p.basename(f.kok.path)}.json'),
    );
    try {
      jsonYaz(f.kok.path, hedef.path, veri);
      expect(jsonDecode(hedef.readAsStringSync(encoding: utf8)), veri);
      expect(
        () => jsonYaz(f.kok.path, p.join(f.kok.path, 'cikti.json'), veri),
        throwsA(isA<FileSystemException>()),
      );
    } finally {
      if (hedef.existsSync()) hedef.deleteSync();
    }
  });

  for (final alan in ['baslangicKodu', 'baslangicDosyasi', 'baslik']) {
    test('Manifest / gerçek görev $alan uyuşmazlığı engellenir', () {
      f.dersler[0]['gorevler'][0][alan] = 'uyuşmuyor';
      f.kaydet();
      expect(
        f.oku,
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'dosya ve ders',
            allOf(contains('TM-DEMO-00'), contains('teknik-mulakat-v2.json')),
          ),
        ),
      );
    });
  }
  test('Farklı veya eksik kontrol uydurulmaz', () {
    f.dersler[0]['gorevler'][0]['kontrol']['girdi'] = 'farklı\n';
    f.kaydet();
    expect(f.oku, throwsFormatException);
    (f.dersler[0]['gorevler'][0]['kontrol'] as Map).remove('girdi');
    f.kaydet();
    expect(f.oku, throwsFormatException);
  });
  test('Yinelenen ders kodu/sırası ve görev numarası reddedilir', () {
    f.dersler[1]['kod'] = f.dersler[0]['kod'];
    f.kaydet();
    expect(f.oku, throwsFormatException);
    f.dersler[1]['kod'] = 'TM-DEMO-27';
    f.dersler[1]['sira'] = f.dersler[0]['sira'];
    f.kaydet();
    expect(f.oku, throwsFormatException);
    f.dersler[1]['sira'] = 1;
    f.dersler[0]['gorevler'][1]['no'] = 1;
    f.kaydet();
    expect(f.oku, throwsFormatException);
  });
  test(
    'Bozuk JSON, desteklenmeyen alan ve eksik manifest açıkça reddedilir',
    () {
      f.yaz('teknik-mulakat-v2.json', '{bozuk');
      expect(f.oku, throwsFormatException);
      f.paket['bilinmeyen'] = 'kaybolmasın';
      f.kaydet();
      expect(f.oku, throwsFormatException);
      File(p.join(f.kok.path, 'teknik-mulakat-v2.json')).deleteSync();
      expect(f.oku, throwsFormatException);
    },
  );
  test('Ek Markdown arşiv kaybı, modül/veri dosyası çalıştırma engelidir', () {
    f.yaz('dersler/TM-DEMO-00/NOT.md', '# Ek not');
    expect(f.plan().kayiplar.join(), contains('NOT.md'));
    f.yaz('dersler/TM-DEMO-00/yardimci.py', '# Ek modül');
    expect(
      f.plan,
      throwsA(
        isA<YuklemeHatasi>().having(
          (e) => e.mesaj,
          'bağımlılık',
          contains('yardimci.py'),
        ),
      ),
    );
  });
  test('Tanımsız kök dosyası sessizce düşürülmez', () {
    f.yaz('ek-dosya.txt', 'Kayıp veri');
    expect(f.oku, throwsFormatException);
  });
  test('Eksik kod dosyası / ders / ilave ders klasörü engellenir', () {
    File(p.join(f.kok.path, 'dersler/TM-DEMO-00/gorevler/say.py')).deleteSync();
    expect(f.oku, throwsFormatException);
    f.yaz('dersler/TM-DEMO-00/gorevler/say.py', DemoKaynak.kod);
    f.yaz('dersler/TM-DEMO-14/README.md', '# Tanımsız');
    expect(f.oku, throwsFormatException);
  });
  test('Bozuk JSON, bilinmeyen alan, yinelenen ders/sıra/görev reddedilir', () {
    f.yaz('teknik-mulakat-v2.json', '{bozuk');
    expect(f.oku, throwsFormatException);
    f.paket['bilinmeyen'] = true;
    f.kaydet();
    expect(f.oku, throwsFormatException);
    f.paket.remove('bilinmeyen');
    f.dersler[1]['sira'] = f.dersler[0]['sira'];
    f.kaydet();
    expect(f.oku, throwsFormatException);
    f.dersler[1]['sira'] = 1;
    f.dersler[1]['kod'] = f.dersler[0]['kod'];
    f.kaydet();
    expect(f.oku, throwsFormatException);
    f.dersler[1]['kod'] = 'TM-DEMO-27';
    f.dersler[0]['gorevler'][1]['no'] = 1;
    f.kaydet();
    expect(f.oku, throwsFormatException);
  });
  test('Ek Markdown açık kayıp; çalışma bağımlılığı kısmi onayla aşılamaz', () {
    f.yaz('dersler/TM-DEMO-00/NOTLAR.md', '# Ek not');
    expect(f.plan().kayiplar.join(), contains('NOTLAR.md'));
    f.yaz('dersler/TM-DEMO-00/yardimci.py', '# bağımlılık');
    expect(
      f.plan,
      throwsA(
        isA<YuklemeHatasi>().having(
          (e) => e.mesaj,
          'neden',
          contains('yardimci.py'),
        ),
      ),
    );
  });
  test('V1 düşürmesi ve kategori/ders kimlik çakışması reddedilir', () {
    final v = f.oku();
    expect(
      () => yuklemePlani(v, {'TM-DEMO-00'}, surum: 1),
      throwsA(isA<YuklemeHatasi>()),
    );
    v['kategoriler'].add({'id': 2, 'kisaltma': 'PY'});
    expect(
      () => yuklemePlani(v, {'TM-DEMO-00'}),
      throwsA(isA<YuklemeHatasi>()),
    );
    v['kategoriler'].removeLast();
    v['egitimler'][1]['id'] = v['egitimler'][0]['id'];
    expect(
      () => yuklemePlani(v, {'TM-DEMO-00', 'TM-DEMO-27'}),
      throwsA(isA<YuklemeHatasi>()),
    );
  });
  test('CLI dry-run sıfır HTTP; arşiv kaybında varsayılan çıkış 2', () async {
    var http = 0;
    final log = <String>[];
    Future<HttpYaniti> gonder(
      String m,
      Uri u,
      Map<String, String> h,
      String? b,
    ) async {
      http++;
      throw StateError('Ağ yasak');
    }

    final args = [
      '--kaynak',
      f.kok.path,
      '--api',
      'http://localhost:5080',
      '--ders',
      'TM-DEMO-00,TM-DEMO-27',
      '--dry-run',
    ];
    expect(await yuklemeKomutu(args, gonder: gonder, yaz: log.add), 2);
    expect(
      await yuklemeKomutu(
        [...args, '--kismi-aktarimi-onayla'],
        gonder: gonder,
        yaz: log.add,
      ),
      0,
    );
    expect(http, 0);
    expect(log.join(), contains('TM-DEMO — Teknik Mülakatlar'));
  });
  test(
    'Mock v2 aktarımı ve geri okuma: PY değişmez, kod/kontrol tamdır',
    () async {
      final api = SahteApi();
      api.kayitlar['PY-01'] = {'id': 1, 'baslik': 'Koru', 'gorevler': []};
      final once = jsonEncode(api.kayitlar['PY-01']);
      Future<HttpYaniti> gonder(
        String m,
        Uri u,
        Map<String, String> h,
        String? b,
      ) async {
        if (u.path == '/api/mobil/kategoriler') {
          return HttpYaniti(
            200,
            jsonEncode([
              {
                'id': 42,
                'kisaltma': 'TM-DEMO',
                'ad': 'Teknik Mülakatlar',
                'aciklama': 'Demo eğitim',
                'sira': 50,
              },
            ]),
          );
        }
        return api.cevap(m, u, h, b);
      }

      final sonuc =
          await IcerikYukleyici(Uri.parse('http://localhost/'), gonder).yukle(
            f.plan(),
            eposta: 'yonetici@example.test',
            sifre: 'test-parolasi',
            kayipOnayi: true,
          );
      expect(sonuc.basarili, isTrue);
      expect(sonuc.dogrulanan, ['TM-DEMO-27', 'TM-DEMO-00']);
      expect(api.aktarimSayisi, 1);
      expect(jsonEncode(api.kayitlar['PY-01']), once);
      expect(api.sonPaket!['kategoriler'][0]['kisaltma'], 'TM-DEMO');
    },
  );
  test(
    'Farklı mevcut kategori metadatası hiçbir POST göndermeden durur',
    () async {
      final api = SahteApi();
      Future<HttpYaniti> gonder(
        String m,
        Uri u,
        Map<String, String> h,
        String? b,
      ) async {
        if (u.path == '/api/mobil/kategoriler') {
          return HttpYaniti(
            200,
            jsonEncode([
              {
                'id': 42,
                'kisaltma': 'TM-DEMO',
                'ad': 'Başka ad',
                'aciklama': 'Demo eğitim',
                'sira': 50,
              },
            ]),
          );
        }
        return api.cevap(m, u, h, b);
      }

      final sonuc =
          await IcerikYukleyici(Uri.parse('http://localhost/'), gonder).yukle(
            f.plan(),
            eposta: 'yonetici@example.test',
            sifre: 'test-parolasi',
            kayipOnayi: true,
          );
      expect(sonuc.basarili, isFalse);
      expect(sonuc.hata, contains('mevcut kategorinin ad'));
      expect(api.istekler.where((s) => s.startsWith('POST')), isEmpty);
    },
  );
}
