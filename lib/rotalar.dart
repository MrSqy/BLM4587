import 'package:flutter/material.dart';

import 'ekranlar/ana_iskelet.dart';
import 'ekranlar/hakkinda_ekrani.dart';
import 'ekranlar/oturum_formu_ekrani.dart';

// İsimli rotalar. Yeni bir sayfa eklerken adını buraya sabit olarak yazıp
// tabloya ekleyin; geçişlerde Navigator.pushNamed(context, Rotalar.xxx) kullanın.
class Rotalar {
  static const String anaIskelet = '/';
  static const String hakkinda = '/hakkinda';
  static const String giris = '/giris';
  static const String kayit = '/kayit';

  static final Map<String, WidgetBuilder> tablo = {
    anaIskelet: (context) => const AnaIskelet(),
    hakkinda: (context) => const HakkindaEkrani(),
    giris: (context) => const OturumFormuEkrani(),
    kayit: (context) => const OturumFormuEkrani(kayit: true),
  };
}
