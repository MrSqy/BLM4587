// Eğitim alanı: Python dili, Teknik Mülakat Algoritmalar vb.
// Alanlar BLM4581 Web API'sinin JSON çıktısıyla aynıdır.
class Kategori {
  final int id;
  final String ad;
  final String kisaltma;
  final String aciklama;
  final int sira;

  const Kategori({
    required this.id,
    required this.ad,
    required this.kisaltma,
    this.aciklama = '',
    this.sira = 0,
  });

  factory Kategori.fromJson(Map<String, dynamic> json) {
    return Kategori(
      id: json['id'] as int,
      ad: json['ad'] as String,
      kisaltma: json['kisaltma'] as String,
      aciklama: json['aciklama'] as String? ?? '',
      sira: json['sira'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ad': ad,
      'kisaltma': kisaltma,
      'aciklama': aciklama,
      'sira': sira,
    };
  }
}
