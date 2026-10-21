// Dersteki bir alıştırma. no, test dosyasındaki test_gorev_N fonksiyonlarıyla eşleşir.
class Gorev {
  final int id;
  final int egitimId;
  final int no;
  final String baslik;
  final String aciklama;

  const Gorev({
    required this.id,
    required this.egitimId,
    required this.no,
    required this.baslik,
    this.aciklama = '',
  });

  factory Gorev.fromJson(Map<String, dynamic> json) {
    return Gorev(
      id: json['id'] as int,
      egitimId: json['egitimId'] as int,
      no: json['no'] as int,
      baslik: json['baslik'] as String,
      aciklama: json['aciklama'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'egitimId': egitimId,
      'no': no,
      'baslik': baslik,
      'aciklama': aciklama,
    };
  }
}
