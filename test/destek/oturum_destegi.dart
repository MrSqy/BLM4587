import 'dart:convert';
import 'package:egitim_platformu/servisler/oturum_servisi.dart';
import 'package:egitim_platformu/servisler/api_istemcisi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class BellekDeposu implements OturumDeposu {
  String? veri;
  bool yazmaHatasi = false;
  @override
  Future<String?> oku() async => veri;
  @override
  Future<void> yaz(String? yeni) async {
    if (yazmaHatasi) {
      throw StateError('Depo kilitli');
    }
    veri = yeni;
  }
}

Map<String, dynamic> oturumYaniti({DateTime? bitis}) => {
  'token': 'test-token',
  'bitis': (bitis ?? DateTime.now().add(const Duration(minutes: 15)))
      .toUtc()
      .toIso8601String(),
  'kullanici': {
    'id': 'ogrenci-1',
    'eposta': 'ogrenci@ornek.com',
    'adSoyad': 'Örnek Öğrenci',
  },
};
http.Response jsonYanit(Object veri, [int kod = 200]) => http.Response(
  jsonEncode(veri),
  kod,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
OturumServisi denemeOturumu({
  BellekDeposu? depo,
  Future<http.Response> Function(http.Request)? yanit,
}) => OturumServisi(
  ApiIstemcisi(
    istemci: MockClient(yanit ?? (r) async => jsonYanit(oturumYaniti())),
  ),
  depo ?? BellekDeposu(),
);
