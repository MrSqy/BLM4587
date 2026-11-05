// Dersteki bir alıştırma. no, test dosyasındaki test_gorev_N fonksiyonlarıyla eşleşir.
class Gorev {
  final int id;
  final int egitimId;
  final int no;
  final String baslik;
  final String aciklama;
  final String tur;
  final String? baslangicDosyasi;
  final String baslangicKodu;
  final GorevKontrolu? kontrol;
  bool get kodGorevi =>
      tur == 'kod' &&
      baslangicDosyasi != null &&
      kontrol?.tur == 'standart-cikti';

  const Gorev({
    required this.id,
    required this.egitimId,
    required this.no,
    required this.baslik,
    this.aciklama = '',
    this.tur = 'eski-pytest',
    this.baslangicDosyasi,
    this.baslangicKodu = '',
    this.kontrol,
  });

  factory Gorev.fromJson(Map<String, dynamic> json) {
    return Gorev(
      tur: json['tur'] as String? ?? 'eski-pytest',
      baslangicDosyasi: json['baslangicDosyasi'] as String?,
      baslangicKodu: json['baslangicKodu'] as String? ?? '',
      kontrol: json['kontrol'] == null
          ? null
          : GorevKontrolu.fromJson(json['kontrol'] as Map<String, dynamic>),
      id: json['id'] as int,
      egitimId: json['egitimId'] as int,
      no: json['no'] as int,
      baslik: json['baslik'] as String,
      aciklama: json['aciklama'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tur': tur,
      'baslangicDosyasi': baslangicDosyasi,
      'baslangicKodu': baslangicKodu,
      'kontrol': kontrol?.toJson(),
      'id': id,
      'egitimId': egitimId,
      'no': no,
      'baslik': baslik,
      'aciklama': aciklama,
    };
  }
}

class GorevKontrolu {
  final String tur, beklenenCikti, girdi;
  final int beklenenCikisKodu;
  final List<String> kullanilmamali;
  const GorevKontrolu({
    this.tur = 'standart-cikti',
    required this.beklenenCikti,
    this.girdi = '',
    this.beklenenCikisKodu = 0,
    this.kullanilmamali = const [],
  });
  factory GorevKontrolu.fromJson(Map<String, dynamic> json) => GorevKontrolu(
    tur: json['tur'] as String,
    beklenenCikti: json['beklenenCikti'] as String,
    girdi: json['girdi'] as String,
    beklenenCikisKodu: json['beklenenCikisKodu'] as int,
    kullanilmamali: (json['kullanilmamali'] as List).cast<String>(),
  );
  Map<String, dynamic> toJson() => {
    'tur': tur,
    'beklenenCikti': beklenenCikti,
    'girdi': girdi,
    'beklenenCikisKodu': beklenenCikisKodu,
    'kullanilmamali': kullanilmamali,
  };
}
