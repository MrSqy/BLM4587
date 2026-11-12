import '../modeller/gonderim.dart';
import 'api_istemcisi.dart';

class GonderimServisi {
  final ApiIstemcisi api;
  const GonderimServisi(this.api);

  Future<GonderimSayfasi> liste(int sayfa) async {
    final veri = await api.gonderimGecmisiIste(sayfa: sayfa);
    final sonuc = GonderimSayfasi.fromJson(veri as Map<String, dynamic>);
    if (sonuc.sayfa != sayfa) {
      throw const FormatException('Gönderim sayfası eşleşmiyor.');
    }
    return sonuc;
  }

  Future<GonderimDetayi> detay(int id) async {
    final veri = await api.gonderimGecmisiIste(id: id);
    final sonuc = GonderimDetayi.fromJson(veri as Map<String, dynamic>);
    if (sonuc.gonderim.id != id) {
      throw const FormatException('Gönderim kimliği eşleşmiyor.');
    }
    return sonuc;
  }
}
