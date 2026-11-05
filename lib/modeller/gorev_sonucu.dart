class GorevSonucu {
  final int no;
  final bool basarili;
  final String durum, cikti, hata;
  final int? cikisKodu;
  final bool? ciktiEslesiyor, cikisKoduEslesiyor;
  final List<String> kuralIhlalleri;
  GorevSonucu.fromJson(Map<String, dynamic> j)
    : no = j['no'] as int,
      basarili = j['basarili'] as bool,
      durum = j['durum'] as String,
      cikti = j['cikti'] as String,
      hata = j['hata'] as String,
      cikisKodu = j['cikisKodu'] as int?,
      ciktiEslesiyor = j['ciktiEslesiyor'] as bool?,
      cikisKoduEslesiyor = j['cikisKoduEslesiyor'] as bool?,
      kuralIhlalleri = (j['kuralIhlalleri'] as List).cast<String>();
  bool get testGecti =>
      basarili &&
      durum == 'basarili' &&
      ciktiEslesiyor == true &&
      cikisKoduEslesiyor == true &&
      kuralIhlalleri.isEmpty;
}
