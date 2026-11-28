import 'dart:convert';

import 'yerel_dosya_deposu.dart';

class DersNotu {
  final String metin;
  final bool yerImi;
  const DersNotu({this.metin = '', this.yerImi = false});
}

class DersNotuDeposu {
  final YerelDosyaDeposu dosyalar;
  const DersNotuDeposu({this.dosyalar = yerelDosyaDeposu});

  Future<DersNotu> oku(String sunucu, String hesap, int dersId) async {
    final ham = await dosyalar.oku(
      'ders-notlari',
      sunucu,
      hesap,
      '$dersId.json',
    );
    if (ham == null) return const DersNotu();
    return _ayristir(ham);
  }

  Future<Map<int, DersNotu>> liste(String sunucu, String hesap) async {
    final kayitlar = <int, DersNotu>{};
    final dosyalar = await this.dosyalar.dosyalariListele(
      'ders-notlari',
      sunucu,
      hesap,
    );
    final adBicimi = RegExp(r'^(\d+)\.json$');
    for (final dosya in dosyalar) {
      final id = adBicimi.firstMatch(dosya.uri.pathSegments.last)?.group(1);
      if (id == null) continue;
      final not = _ayristir(await dosya.readAsString());
      if (not.yerImi || not.metin.trim().isNotEmpty) {
        kayitlar[int.parse(id)] = not;
      }
    }
    return kayitlar;
  }

  static DersNotu _ayristir(String ham) {
    final veri = jsonDecode(ham);
    if (veri is! Map || veri['metin'] is! String || veri['yerImi'] is! bool) {
      throw const FormatException('Ders notu okunamadı.');
    }
    return DersNotu(
      metin: veri['metin'] as String,
      yerImi: veri['yerImi'] as bool,
    );
  }

  Future<void> yaz(String sunucu, String hesap, int dersId, DersNotu not) =>
      dosyalar.yaz(
        'ders-notlari',
        sunucu,
        hesap,
        '$dersId.json',
        jsonEncode({'metin': not.metin, 'yerImi': not.yerImi}),
      );
}
