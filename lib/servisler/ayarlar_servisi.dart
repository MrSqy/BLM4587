import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AyarlarServisi extends ChangeNotifier {
  late final _tercihler = SharedPreferencesAsync();

  ThemeMode tema = ThemeMode.system;
  double yaziOlcegi = 1;
  static const olcekler = [1.0, 1.15, 1.3];

  Future<void> hazirla() async {
    try {
      final kayitliTema = await _tercihler.getString('ayar_tema');
      final kayitliOlcek = await _tercihler.getDouble('ayar_yazi_olcegi');
      tema = ThemeMode.values.firstWhere(
        (deger) => deger.name == kayitliTema,
        orElse: () => ThemeMode.system,
      );
      yaziOlcegi = olcekler.contains(kayitliOlcek) ? kayitliOlcek! : 1;
      notifyListeners();
    } catch (_) {
      // Depo açılmazsa uygulama mevcut varsayılanlarla çalışır.
    }
  }

  Future<void> temayiSec(ThemeMode secim) async {
    await _tercihler.setString('ayar_tema', secim.name);
    tema = secim;
    notifyListeners();
  }

  Future<void> yaziOlceginiSec(double secim) async {
    if (!olcekler.contains(secim)) throw ArgumentError.value(secim, 'secim');
    await _tercihler.setDouble('ayar_yazi_olcegi', secim);
    yaziOlcegi = secim;
    notifyListeners();
  }
}

final ayarlarServisi = AyarlarServisi();
