import 'gorev.dart';

// Eğitim deposundaki bir ders klasörü (ör. dersler/PY-03).
class Egitim {
  final int id;
  final int? kategoriId;
  final String kod;
  final String baslik;
  final int sira;
  final String icerikMarkdown; // ALISTIRMALAR.md
  final String baslangicKodu; // calisma.py
  final String testKodu; // test_alistirmalar.py
  final List<Gorev> gorevler;
  final bool misafireAcik;
  final bool erisilebilir;
  final String ozet;
  final int? toplamGorev;
  int get gorevSayisi => toplamGorev ?? gorevler.length;

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
    this.misafireAcik = false,
    this.erisilebilir = false,
    this.ozet = '',
    this.toplamGorev,
  });

  factory Egitim.fromJson(Map<String, dynamic> json) {
    final gorevListesi = json['gorevler'] as List<dynamic>? ?? [];
    return Egitim(
      misafireAcik: json['misafireAcik'] as bool? ?? false,
      ozet: json['ozet'] as String? ?? '',
      toplamGorev: json['gorevSayisi'] as int?,
      id: json['id'] as int,
      kategoriId: json['kategoriId'] as int?,
      erisilebilir: json['erisilebilir'] as bool? ?? false,
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
      'misafireAcik': misafireAcik,
      'erisilebilir': erisilebilir,
      'ozet': ozet,
      if (toplamGorev != null) 'gorevSayisi': toplamGorev,
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
