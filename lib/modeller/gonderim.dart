class GonderimOzeti {
  final int id, egitimId, sureMs;
  final int? gorevId, gorevNo, cikisKodu;
  final String ders, durum;
  final String? gorev;
  final bool basarili;
  final DateTime tarih;

  GonderimOzeti.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      egitimId = json['egitimId'] as int,
      sureMs = json['sureMs'] as int,
      gorevId = json['gorevId'] as int?,
      gorevNo = json['gorevNo'] as int?,
      cikisKodu = json['cikisKodu'] as int?,
      ders = json['ders'] as String,
      gorev = json['gorev'] as String?,
      durum = json['durum'] as String,
      basarili = json['basarili'] as bool,
      tarih = DateTime.parse(json['tarih'] as String);

  String get sonucEtiketi => switch (durum) {
    'zaman_asimi' => 'Süre sınırı aşıldı',
    'cikti_siniri' => 'Çıktı sınırı aşıldı',
    'test_yok' => 'Test bulunamadı',
    'hata' => 'Çalıştırma hatası',
    _ => basarili ? 'Başarılı' : 'Başarısız',
  };
}

class GonderimSayfasi {
  final int toplam, sayfa, sayfaBoyutu;
  final List<GonderimOzeti> kayitlar;

  GonderimSayfasi.fromJson(Map<String, dynamic> json)
    : toplam = json['toplam'] as int,
      sayfa = json['sayfa'] as int,
      sayfaBoyutu = json['sayfaBoyutu'] as int,
      kayitlar = (json['kayitlar'] as List)
          .map((kayit) => GonderimOzeti.fromJson(kayit as Map<String, dynamic>))
          .toList(growable: false) {
    if (toplam < 0 ||
        sayfa < 1 ||
        sayfaBoyutu < 1 ||
        kayitlar.length > sayfaBoyutu) {
      throw const FormatException('Geçersiz gönderim sayfası.');
    }
  }

  bool get sonrakiVar => kayitlar.isNotEmpty && sayfa * sayfaBoyutu < toplam;
}

class GonderimDetayi {
  final GonderimOzeti gonderim;
  final String kod, cikti, hata;

  GonderimDetayi.fromJson(Map<String, dynamic> json)
    : gonderim = GonderimOzeti.fromJson(
        json['gonderim'] as Map<String, dynamic>,
      ),
      kod = json['kod'] as String,
      cikti = json['cikti'] as String,
      hata = json['hata'] as String;
}
