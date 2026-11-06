import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'yukleme_plani.dart';

class HttpYaniti {
  final int durum;
  final String govde;
  HttpYaniti(this.durum, this.govde);
}

typedef HttpGonder =
    Future<HttpYaniti> Function(
      String metot,
      Uri adres,
      Map<String, String> basliklar,
      String? govde,
    );

/// Tek hedefe ait bellek içi çerezler; yönlendirme ve otomatik tekrar yoktur.
class ApiBaglantisi {
  final HttpClient _client = HttpClient();
  final Map<String, Cookie> _cerezler = {};
  final Duration zamanAsimi;
  ApiBaglantisi({this.zamanAsimi = const Duration(seconds: 20)});
  Future<HttpYaniti> gonder(
    String metot,
    Uri adres,
    Map<String, String> basliklar,
    String? govde,
  ) async {
    try {
      return await _istek(metot, adres, basliklar, govde).timeout(zamanAsimi);
    } on TimeoutException {
      _client.close(force: true);
      throw YuklemeHatasi('Zaman aşımı; otomatik tekrar yapılmadı.');
    } on SocketException {
      throw YuklemeHatasi(
        'API bağlantısı kurulamadı/kesildi; otomatik tekrar yapılmadı.',
      );
    } on HandshakeException {
      throw YuklemeHatasi(
        'TLS sertifikası doğrulanamadı; sertifika kontrolü devre dışı bırakılmadı.',
      );
    } on HttpException {
      throw YuklemeHatasi(
        'HTTP bağlantısı başarısız. Yazma sonucu belirsiz olabilir; otomatik tekrar yapılmadı.',
      );
    }
  }

  Future<HttpYaniti> _istek(
    String metot,
    Uri adres,
    Map<String, String> basliklar,
    String? govde,
  ) async {
    final istek = await _client.openUrl(metot, adres);
    istek.followRedirects = false;
    basliklar.forEach(istek.headers.set);
    for (final c in _cerezler.values) {
      if ((!c.secure || adres.scheme == 'https') &&
          (c.expires == null || c.expires!.isAfter(DateTime.now())) &&
          adres.path.startsWith(c.path ?? '/')) {
        istek.cookies.add(c);
      }
    }
    if (govde != null) istek.add(utf8.encode(govde));
    final yanit = await istek.close();
    for (final c in yanit.cookies) {
      _cerezler['${c.name}|${c.path ?? '/'}'] = c;
    }
    final bytes = <int>[];
    await for (final parca in yanit) {
      bytes.addAll(parca);
      if (bytes.length > 8 * 1024 * 1024) {
        throw YuklemeHatasi('API yanıtı 8 MiB sınırını aştı.');
      }
    }
    return HttpYaniti(yanit.statusCode, utf8.decode(bytes));
  }

  void kapat() => _client.close(force: true);
}

class YuklemeSonucu {
  final List<String> dogrulanan = [];
  final List<String> bekleyen;
  bool kayitOnaylandi = false;
  bool aktarimIstegiDenendi = false;
  String? hata;
  YuklemeSonucu(this.bekleyen);
  bool get basarili => hata == null && bekleyen.isEmpty;
  String get ozet =>
      'Aktarım POST: ${aktarimIstegiDenendi ? 'denendi' : 'gönderilmedi'}. '
      'Sunucu kaydı: ${kayitOnaylandi ? 'paket kaydedildi' : 'doğrulanmadı'}. '
      'Geri okunarak doğrulanan: ${dogrulanan.isEmpty ? 'yok' : dogrulanan.join(', ')}. '
      'Tamamlanmayan/doğrulanamayan: ${bekleyen.isEmpty ? 'yok' : bekleyen.join(', ')}.';
}

class IcerikYukleyici {
  final Uri temel;
  final HttpGonder gonder;
  String? _okumaTokeni;
  IcerikYukleyici(this.temel, this.gonder);
  Future<HttpYaniti> _istek(
    String metot,
    String yol, {
    Map<String, String> basliklar = const {},
    String? govde,
  }) => gonder(metot, temel.resolve(yol), basliklar, govde);
  void _durum(HttpYaniti yanit, String adim) {
    if (yanit.durum == 200) return;
    final aciklama = switch (yanit.durum) {
      401 => 'oturum geçersiz veya giriş gerekli',
      403 => 'yönetici yetkisi yok',
      400 => 'doğrulama/CSRF hatası',
      409 => 'çakışma; aktarım paketi geri alındı',
      413 => 'paket boyutu sınırı aşıldı',
      429 => 'istek sınırı aşıldı; otomatik tekrar yapılmadı',
      >= 500 => 'sunucu hatası; kayıt sonucu belirsiz olabilir',
      _ => 'beklenmeyen HTTP yanıtı (yönlendirmeler izlenmez)',
    };
    // Gövde hassas veri içerebilir; sunucu metni/logları yazdırılmaz.
    throw YuklemeHatasi('$adim: HTTP ${yanit.durum}, $aciklama.');
  }

  dynamic _json(HttpYaniti yanit) {
    try {
      return jsonDecode(yanit.govde);
    } on FormatException {
      throw YuklemeHatasi('API geçerli JSON döndürmedi.');
    }
  }

  Future<void> _giris(String eposta, String sifre) async {
    if (eposta.isEmpty || sifre.isEmpty) {
      throw YuklemeHatasi(
        'EGITIM_EPOSTA ve EGITIM_SIFRE ortam değişkenleri gerekli.',
      );
    }
    final form = await _istek('GET', 'Hesap/Giris');
    _durum(form, 'Giriş formu');
    String? token;
    for (final input in RegExp(
      r'<input\b[^>]*>',
      caseSensitive: false,
    ).allMatches(form.govde)) {
      final alanlar = <String, String>{};
      for (final attr in RegExp(
        '([\\w-]+)\\s*=\\s*["\x27]([^"\x27]*)["\x27]',
      ).allMatches(input[0]!)) {
        alanlar[attr[1]!.toLowerCase()] = attr[2]!;
      }
      if (alanlar['name'] == '__RequestVerificationToken') {
        token = alanlar['value'];
      }
    }
    if (token == null || token.isEmpty) {
      throw YuklemeHatasi('Giriş formunda CSRF tokenı bulunamadı.');
    }
    token = token
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#x27;', "'");
    final govde =
        {
              '__RequestVerificationToken': token,
              'Input.Eposta': eposta,
              'Input.Sifre': sifre,
              'Input.BeniHatirla': 'false',
              'ReturnUrl': '/',
            }.entries
            .map(
              (e) =>
                  '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
            )
            .join('&');
    final sonuc = await _istek(
      'POST',
      'Hesap/Giris',
      basliklar: {'content-type': 'application/x-www-form-urlencoded'},
      govde: govde,
    );
    if (sonuc.durum != 302 && sonuc.durum != 303) {
      if (sonuc.durum != 200) _durum(sonuc, 'Giriş');
      throw YuklemeHatasi(
        'Giriş başarısız; hesap/parola veya form doğrulamasını kontrol edin.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> _dersAra(String kod) async {
    final bulunan = <Map<String, dynamic>>[];
    var sayfa = 1;
    while (true) {
      final yanit = await _istek(
        'GET',
        'api/egitimler?q=${Uri.encodeQueryComponent(kod)}&sayfaBoyutu=100&sayfa=$sayfa',
      );
      _durum(yanit, '$kod arama');
      final veri = _json(yanit) as Map<String, dynamic>;
      final liste = (veri['egitimler'] as List).cast<Map<String, dynamic>>();
      bulunan.addAll(liste.where((d) => d['kod'] == kod));
      if (sayfa * 100 >= (veri['toplam'] as int)) break;
      if (liste.isEmpty || sayfa >= 1000000) {
        throw YuklemeHatasi('API sayfalama yanıtı tutarsız.');
      }
      sayfa++;
    }
    return bulunan;
  }

  Future<void> _v2SunucuyuDogrula() async {
    final yanit = await _istek('GET', 'swagger/v1/swagger.json');
    _durum(yanit, 'V2 sözleşme kontrolü (API yeniden başlatılmalı)');
    final doc = _json(yanit) as Map;
    final schemas = (doc['components'] as Map?)?['schemas'] as Map?;
    final paket = (schemas?['IcerikPaketi'] as Map?)?['properties'] as Map?;
    final gorev = (schemas?['GorevAktarimi'] as Map?)?['properties'] as Map?;
    final kontrol = (schemas?['GorevKontrolu'] as Map?)?['properties'] as Map?;
    final max = (paket?['surum'] as Map?)?['maximum'];
    final paths = doc['paths'] as Map?;
    if (max is! num ||
        max < 2 ||
        gorev == null ||
        kontrol == null ||
        ![
          'tur',
          'baslangicDosyasi',
          'baslangicKodu',
          'kontrol',
        ].every(gorev.containsKey) ||
        ![
          'tur',
          'beklenenCikti',
          'girdi',
          'beklenenCikisKodu',
          'kullanilmamali',
        ].every(kontrol.containsKey) ||
        paths?.containsKey('/api/mobil/egitimler/{id}/gorevler/{no}/test') !=
            true) {
      throw YuklemeHatasi(
        'Çalışan API v2 sözleşmesi doğrulanamadı. Güncel kodu derleyip migration durumunu kontrol ederek API’yi yeniden başlatın. Hiçbir POST gönderilmedi.',
      );
    }
  }

  Future<void> _mevcutKayitlariKoru(
    YuklemePlani plan,
    bool v2GecisOnayi,
  ) async {
    for (final ders in plan.dersler) {
      final eslesen = await _dersAra(ders['kod'] as String);
      if (eslesen.length > 1) {
        throw YuklemeHatasi(
          '${ders['kod']}: birden fazla sunucu kaydı bulundu.',
        );
      }
      // TestKodu GET yanıtında yoktur. Boş değerle güncellemek güvenli değildir.
      if (eslesen.isNotEmpty &&
          (ders['baslangicKodu'] == '' || ders['testKodu'] == '') &&
          !(plan.paket['surum'] == 2 && v2GecisOnayi)) {
        throw YuklemeHatasi(
          '${ders['kod']}: mevcut kayıt var. Boş başlangıç/test kodu mevcut veriyi silebilir; API test kodunu geri vermiyor. V2 geçişi DB yedeği ve --v2-gecisini-onayla gerektirir. Hiçbir aktarım isteği gönderilmedi.',
        );
      }
    }
    final yanit = await _istek('GET', 'api/mobil/kategoriler');
    _durum(yanit, 'Kategori okuma');
    final kategoriler = (_json(yanit) as List).cast<Map<String, dynamic>>();
    for (final dynamic kategori in plan.paket['kategoriler']) {
      final eslesen = kategoriler
          .where((k) => k['kisaltma'] == kategori['kisaltma'])
          .toList();
      if (eslesen.length > 1) {
        throw YuklemeHatasi('Kategori kısaltması sunucuda yineleniyor.');
      }
      if (eslesen.isNotEmpty) {
        for (final alan in ['ad', 'aciklama', 'sira']) {
          kategori[alan] = eslesen.single[alan];
        }
      }
    }
  }

  Future<HttpYaniti> _detay(int id, String eposta, String sifre) async {
    Future<HttpYaniti> oku() => _istek(
      'GET',
      'api/mobil/egitimler/$id',
      basliklar: {
        if (_okumaTokeni != null) 'Authorization': 'Bearer $_okumaTokeni',
      },
    );
    var yanit = await oku();
    if (yanit.durum == 401 && _okumaTokeni == null) {
      final giris = await _istek(
        'POST',
        'api/hesap/giris',
        basliklar: {'content-type': 'application/json'},
        govde: jsonEncode({'eposta': eposta, 'sifre': sifre}),
      );
      _durum(giris, 'Geri okuma JWT girişi');
      final veri = _json(giris) as Map;
      if (veri['tokenType'] != 'Bearer' ||
          veri['accessToken'] is! String ||
          (veri['accessToken'] as String).isEmpty) {
        throw YuklemeHatasi('Geri okuma token yanıtı geçersiz.');
      }
      _okumaTokeni = veri['accessToken'] as String;
      yanit =
          await oku(); // Yalnız GET tekrarlanır; aktarım POST'u tekrarlanmaz.
    }
    return yanit;
  }

  Future<void> _dogrula(
    YuklemePlani plan,
    YuklemeSonucu sonuc,
    String eposta,
    String sifre,
  ) async {
    final kategoriYaniti = await _istek('GET', 'api/mobil/kategoriler');
    _durum(kategoriYaniti, 'Kategori doğrulama');
    final kategoriler = (_json(kategoriYaniti) as List)
        .cast<Map<String, dynamic>>();
    for (final ders in plan.dersler) {
      final kod = ders['kod'] as String;
      final eslesen = await _dersAra(kod);
      if (eslesen.length != 1 ||
          eslesen.single['id'] is! int ||
          (eslesen.single['id'] as int) <= 0) {
        throw YuklemeHatasi('$kod: sunucu kimliği/kodu doğrulanamadı.');
      }
      final id = eslesen.single['id'];
      final yanit = await _detay(id as int, eposta, sifre);
      _durum(yanit, '$kod geri okuma');
      final veri = _json(yanit) as Map<String, dynamic>;
      for (final alan in [
        'kod',
        'baslik',
        'sira',
        'icerikMarkdown',
        'baslangicKodu',
      ]) {
        if (veri[alan] != ders[alan]) {
          throw YuklemeHatasi('$kod: $alan geri okuma uyuşmazlığı.');
        }
      }
      final kaynakKategori = (plan.paket['kategoriler'] as List)
          .cast<Map<String, dynamic>>()
          .singleWhere(
            (k) => (k['egitimler'] as List).any((dynamic d) => d['kod'] == kod),
          );
      final kategori = kategoriler
          .where((k) => k['kisaltma'] == kaynakKategori['kisaltma'])
          .toList();
      if (kategori.length != 1 ||
          kategori.single['id'] is! int ||
          (kategori.single['id'] as int) <= 0 ||
          veri['id'] != id ||
          veri['kategoriId'] != kategori.single['id'] ||
          veri['kategoriId'] != eslesen.single['kategoriId']) {
        throw YuklemeHatasi('$kod: ders/kategori ilişkisi doğrulanamadı.');
      }
      final gelen = (veri['gorevler'] as List).cast<Map<String, dynamic>>();
      final istenen = (ders['gorevler'] as List).cast<Map<String, dynamic>>();
      if (gelen.length != istenen.length ||
          gelen.map((g) => g['id']).toSet().length != gelen.length) {
        throw YuklemeHatasi('$kod: görev sayısı/kimlikleri uyuşmuyor.');
      }
      for (final gorev in istenen) {
        final es = gelen.where((g) => g['no'] == gorev['no']).toList();
        if (es.length != 1 ||
            es.single['id'] is! int ||
            (es.single['id'] as int) <= 0 ||
            es.single['egitimId'] != id ||
            es.single['baslik'] != gorev['baslik'] ||
            es.single['aciklama'] != gorev['aciklama']) {
          throw YuklemeHatasi(
            '$kod görev ${gorev['no']}: metin/ilişki doğrulanamadı.',
          );
        }
        if (plan.paket['surum'] == 2) {
          for (final alan in [
            'tur',
            'baslangicDosyasi',
            'baslangicKodu',
            'kontrol',
          ]) {
            if (!_jsonEsit(es.single[alan], gorev[alan])) {
              throw YuklemeHatasi(
                '$kod görev ${gorev['no']}: v2 $alan geri okuma uyuşmazlığı.',
              );
            }
          }
        }
      }
      sonuc.dogrulanan.add(kod);
      sonuc.bekleyen.remove(kod);
    }
  }

  Future<YuklemeSonucu> yukle(
    YuklemePlani plan, {
    required String eposta,
    required String sifre,
    bool kayipOnayi = false,
    bool v2GecisOnayi = false,
  }) async {
    final sonuc = YuklemeSonucu(
      plan.dersler.map((d) => d['kod'] as String).toList(),
    );
    try {
      if (plan.kayiplar.isNotEmpty && !kayipOnayi) {
        throw YuklemeHatasi(
          'API bazı alanları saklamıyor. Varsayılan olarak yükleme engellendi; dry-run raporunu inceleyin.',
        );
      }
      if (plan.paket['surum'] == 2) await _v2SunucuyuDogrula();
      await _mevcutKayitlariKoru(plan, v2GecisOnayi);
      await _giris(eposta, sifre);
      final csrf = await _istek('GET', 'api/icerik/antiforgery');
      _durum(csrf, 'Yönetici CSRF tokenı');
      final token = (_json(csrf) as Map)['token'];
      if (token is! String || token.isEmpty) {
        throw YuklemeHatasi('CSRF tokenı geçersiz.');
      }
      sonuc.aktarimIstegiDenendi = true;
      final yanit = await _istek(
        'POST',
        'api/icerik/aktar',
        basliklar: {
          'content-type': 'application/json; charset=utf-8',
          'X-CSRF-TOKEN': token,
        },
        govde: jsonEncode(plan.paket),
      );
      _durum(yanit, 'Toplu aktarım');
      sonuc.kayitOnaylandi = true;
      final sayilar = _json(yanit) as Map;
      if (sayilar['egitimSayisi'] != plan.dersler.length ||
          sayilar['gorevSayisi'] !=
              plan.dersler.fold<int>(
                0,
                (n, d) => n + (d['gorevler'] as List).length,
              ) ||
          sayilar['kategoriSayisi'] !=
              (plan.paket['kategoriler'] as List).length) {
        throw YuklemeHatasi(
          'Sunucu kayıt sayıları beklenen paketle uyuşmuyor.',
        );
      }
      await _dogrula(plan, sonuc, eposta, sifre);
    } on YuklemeHatasi catch (e) {
      sonuc.hata = e.mesaj;
    } on FormatException {
      sonuc.hata = 'API yanıtı çözümlenemedi; kayıt sonucu doğrulanamadı.';
    } on TypeError {
      sonuc.hata =
          'API yanıtı sözleşmeyle uyuşmuyor; kayıt sonucu doğrulanamadı.';
    }
    return sonuc;
  }
}

bool _jsonEsit(dynamic a, dynamic b) {
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every((dynamic k) => b.containsKey(k) && _jsonEsit(a[k], b[k]));
  }
  if (a is List && b is List) {
    return a.length == b.length &&
        List.generate(a.length, (i) => i).every((i) => _jsonEsit(a[i], b[i]));
  }
  return a == b;
}
