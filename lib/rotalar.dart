import 'package:flutter/material.dart';

import 'ekranlar/ana_iskelet.dart';
import 'ekranlar/ayarlar_ekrani.dart';
import 'ekranlar/hakkinda_ekrani.dart';
import 'ekranlar/kaydedilen_dersler_ekrani.dart';
import 'ekranlar/ders_ilerlemesi_ekrani.dart';
import 'ekranlar/notebook_goruntuleyici_ekrani.dart';
import 'ekranlar/oturum_formu_ekrani.dart';

// İsimli rotalar. Yeni bir sayfa eklerken adını buraya sabit olarak yazıp
// tabloya ekleyin; geçişlerde Navigator.pushNamed(context, Rotalar.xxx) kullanın.
class Rotalar {
  static const String anaIskelet = '/';
  static const String hakkinda = '/hakkinda';
  static const String ayarlar = '/ayarlar';
  static const String dersIlerlemesi = '/ders-ilerlemesi';
  static const String kaydedilenDersler = '/kaydedilen-dersler';
  static const String giris = '/giris';
  static const String kayit = '/kayit';
  static const String ornekNotebook = '/notebook';

  static final Map<String, WidgetBuilder> tablo = {
    anaIskelet: (context) => const AnaIskelet(),
    dersIlerlemesi: (context) => const DersIlerlemesiEkrani(),
    kaydedilenDersler: (context) => const KaydedilenDerslerEkrani(),
    ayarlar: (context) => const AyarlarEkrani(),
    hakkinda: (context) => const HakkindaEkrani(),
    giris: (context) => const OturumFormuEkrani(),
    kayit: (context) => const OturumFormuEkrani(kayit: true),
    ornekNotebook: (context) => const OrnekNotebookEkrani(),
  };
}
