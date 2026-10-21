import 'gorev.dart';

// Eğitim deposundaki bir ders klasörü (ör. dersler/PY-03).
class Egitim {
  final int id;
  final int kategoriId;
  final String kod;
  final String baslik;
  final int sira;
  final String icerikMarkdown; // ALISTIRMALAR.md
  final String baslangicKodu; // calisma.py
  final String testKodu; // test_alistirmalar.py
  final List<Gorev> gorevler;

  const Egitim({
    required this.id,
    required this.kategoriId,
    required this.kod,
    required this.baslik,
    this.sira = 0,
    this.icerikMarkdown = '',
    this.baslangicKodu = '',
    this.testKodu = '',
    this.gorevler = const [],
  });

  factory Egitim.fromJson(Map<String, dynamic> json) {
    final gorevListesi = json['gorevler'] as List<dynamic>? ?? [];
    return Egitim(
      id: json['id'] as int,
      kategoriId: json['kategoriId'] as int,
      kod: json['kod'] as String,
      baslik: json['baslik'] as String,
      sira: json['sira'] as int? ?? 0,
      icerikMarkdown: json['icerikMarkdown'] as String? ?? '',
      baslangicKodu: json['baslangicKodu'] as String? ?? '',
      testKodu: json['testKodu'] as String? ?? '',
      gorevler: gorevListesi
          .map((eleman) => Gorev.fromJson(eleman as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kategoriId': kategoriId,
      'kod': kod,
      'baslik': baslik,
      'sira': sira,
      'icerikMarkdown': icerikMarkdown,
      'baslangicKodu': baslangicKodu,
      'testKodu': testKodu,
      'gorevler': gorevler.map((g) => g.toJson()).toList(),
    };
  }
}
