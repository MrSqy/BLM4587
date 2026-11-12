import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_istemcisi.dart';

abstract class OturumDeposu {
  Future<String?> oku();
  Future<void> yaz(String? veri);
}

class CihazOturumDeposu implements OturumDeposu {
  static const _guvenli = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  SharedPreferencesAsync? _tercihler;
  final FlutterSecureStorage _saklama;
  CihazOturumDeposu({FlutterSecureStorage? saklama, this._tercihler})
    : _saklama = saklama ?? _guvenli;
  @override
  Future<String?> oku() => _saklama.read(key: 'mobil_oturum');
  @override
  Future<void> yaz(String? veri) async {
    if (veri == null) {
      await _saklama.delete(key: 'mobil_oturum');
      try {
        await (_tercihler ??= SharedPreferencesAsync()).remove('oturum_acik');
      } catch (_) {
        /* Hassas olmayan tercih. */
      }
    } else {
      await _saklama.write(key: 'mobil_oturum', value: veri);
      // Preferences yalnızca hassas olmayan oturum tercihini tutar.
      try {
        await (_tercihler ??= SharedPreferencesAsync()).setBool(
          'oturum_acik',
          true,
        );
      } catch (_) {
        /* Oturumun kaynağı güvenli depodur. */
      }
    }
  }
}

class OturumServisi extends ChangeNotifier {
  final ApiIstemcisi api;
  final OturumDeposu depo;
  Map<String, dynamic>? _oturum;
  Timer? _sure;
  final DateTime Function() simdi;
  String? saklamaHatasi;
  OturumServisi(this.api, this.depo, {DateTime Function()? simdi})
    : simdi = simdi ?? DateTime.now {
    api.tokenOku = () => token;
    api.oturumGecersiz = temizle;
  }
  bool get girisYapildi => token != null;
  String? get token =>
      _oturum != null &&
          DateTime.parse(_oturum!['bitis'] as String).isAfter(simdi())
      ? _oturum!['token'] as String
      : null;
  String? get kullaniciId {
    if (!girisYapildi) return null;
    return (_oturum?['kullanici'] as Map?)?['id'] as String?;
  }

  String get adSoyad =>
      (_oturum?['kullanici'] as Map?)?['adSoyad'] as String? ?? 'Misafir';
  String get eposta =>
      (_oturum?['kullanici'] as Map?)?['eposta'] as String? ?? '';

  Future<void> hazirla() async {
    try {
      final raw = await depo.oku();
      if (raw == null) return;
      _oturum = _dogrula(jsonDecode(raw));
      if (token == null) {
        await temizle();
        return;
      }
      _zamanla();
      notifyListeners();
    } catch (_) {
      _oturum = null;
      try {
        await depo.yaz(null);
      } catch (_) {
        /* Kilitli cihazda misafir açılır. */
      }
    }
  }

  Future<void> giris(String eposta, String sifre, {String? adSoyad}) async {
    final data =
        await api.iste(
              'hesap/${adSoyad == null ? 'giris' : 'kayit'}',
              kimlik: false,
              veri: {
                'eposta': eposta.trim(),
                'sifre': sifre,
                if (adSoyad != null) 'adSoyad': adSoyad.trim(),
              },
            )
            as Map<String, dynamic>;
    final dogrulanmis = _dogrula(data);
    if (!DateTime.parse(dogrulanmis['bitis'] as String).isAfter(simdi())) {
      throw const ApiHatasi('Sunucu süresi geçmiş bir oturum döndürdü.');
    }
    try {
      await depo.yaz(jsonEncode(dogrulanmis));
    } catch (_) {
      throw const ApiHatasi(
        'Oturum cihazda saklanamadı. Lütfen tekrar deneyin.',
      );
    }
    _oturum = dogrulanmis;
    saklamaHatasi = null;
    _zamanla();
    notifyListeners();
  }

  Map<String, dynamic> _dogrula(dynamic data) {
    if (data is! Map<String, dynamic> ||
        data['token'] is! String ||
        (data['token'] as String).isEmpty ||
        data['bitis'] is! String ||
        DateTime.tryParse(data['bitis'] as String) == null ||
        data['kullanici'] is! Map ||
        data['kullanici']['id'] is! String ||
        data['kullanici']['eposta'] is! String ||
        data['kullanici']['adSoyad'] is! String) {
      throw const ApiHatasi('Sunucunun oturum yanıtı geçersiz.');
    }
    return data;
  }

  void _zamanla() {
    _sure?.cancel();
    final kalan = DateTime.parse(
      _oturum!['bitis'] as String,
    ).difference(simdi());
    _sure = Timer(kalan.isNegative ? Duration.zero : kalan, temizle);
  }

  Future<void> cikis() async {
    // Sunucu tokenı iptal edemiyorsa kullanıcıya hata göster; sahte başarı yok.
    try {
      await api.iste('hesap/cikis', veri: {});
    } on ApiHatasi catch (e) {
      if (e.durum != 401) rethrow;
    }
    await temizle();
    if (saklamaHatasi != null) {
      throw ApiHatasi(saklamaHatasi!);
    }
  }

  Future<void> temizle() async {
    _sure?.cancel();
    _oturum = null;
    notifyListeners();
    try {
      await depo.yaz(null);
      saklamaHatasi = null;
    } catch (_) {
      saklamaHatasi = 'Cihazdaki oturum kaydı temizlenemedi.';
    }
  }

  @override
  void dispose() {
    _sure?.cancel();
    super.dispose();
  }
}

OturumServisi oturumServisi = OturumServisi(apiIstemcisi, CihazOturumDeposu());
