import 'dart:convert';

import 'package:flutter/services.dart';

import '../modeller/egitim.dart';
import '../modeller/kategori.dart';

// Ekranlar veriyi bu arayüz üzerinden ister. Şimdilik SahteEgitimServisi kullanılır;
// BLM4581 Web API'si hazır olunca aynı arayüzü uygulayan bir http servisi yazılıp
// aşağıdaki egitimServisi değişkeni ona çevrilecek.
abstract class EgitimServisi {
  Future<List<Kategori>> kategorileriGetir();

  // kategoriId verilirse yalnızca o kategorinin dersleri döner.
  Future<List<Egitim>> egitimleriGetir({int? kategoriId});

  // Ders bulunamazsa null döner.
  Future<Egitim?> egitimGetir(int id);
}

// API'nin döndüreceği JSON ile aynı biçimdeki assets/sahte_veri.json dosyasını okur.
class SahteEgitimServisi implements EgitimServisi {
  // Ağ gecikmesini taklit eder; ekranlardaki yükleniyor durumu görülebilsin diye.
  final Duration gecikme;

  SahteEgitimServisi({this.gecikme = const Duration(milliseconds: 400)});

  Map<String, dynamic>? _veri;

  Future<Map<String, dynamic>> _veriyiYukle() async {
    if (_veri == null) {
      final metin = await rootBundle.loadString('assets/sahte_veri.json');
      _veri = jsonDecode(metin) as Map<String, dynamic>;
    }
    await Future.delayed(gecikme);
    return _veri!;
  }

  @override
  Future<List<Kategori>> kategorileriGetir() async {
    final veri = await _veriyiYukle();
    final liste = (veri['kategoriler'] as List<dynamic>)
        .map((eleman) => Kategori.fromJson(eleman as Map<String, dynamic>))
        .toList();
    liste.sort((a, b) => a.sira.compareTo(b.sira));
    return liste;
  }

  @override
  Future<List<Egitim>> egitimleriGetir({int? kategoriId}) async {
    final veri = await _veriyiYukle();
    final liste = (veri['egitimler'] as List<dynamic>)
        .map((eleman) => Egitim.fromJson(eleman as Map<String, dynamic>))
        .where((e) => kategoriId == null || e.kategoriId == kategoriId)
        .toList();
    liste.sort((a, b) => a.sira.compareTo(b.sira));
    return liste;
  }

  @override
  Future<Egitim?> egitimGetir(int id) async {
    final liste = await egitimleriGetir();
    for (final egitim in liste) {
      if (egitim.id == id) return egitim;
    }
    return null;
  }
}

// Uygulamanın kullandığı servis.
EgitimServisi egitimServisi = SahteEgitimServisi();
