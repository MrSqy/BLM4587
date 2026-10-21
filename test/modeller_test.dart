import 'package:egitim_platformu/modeller/egitim.dart';
import 'package:egitim_platformu/modeller/kategori.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Kategori JSON\'dan okunur ve aynı JSON\'a geri yazılır', () {
    final json = {
      'id': 1,
      'ad': 'Python dili',
      'kisaltma': 'PY',
      'aciklama': 'Açıklama',
      'sira': 1,
    };
    final kategori = Kategori.fromJson(json);
    expect(kategori.ad, 'Python dili');
    expect(kategori.toJson(), json);
  });

  test('Egitim görev listesiyle birlikte okunur', () {
    final egitim = Egitim.fromJson({
      'id': 3,
      'kategoriId': 1,
      'kod': 'PY-03',
      'baslik': 'Koleksiyonlar',
      'gorevler': [
        {
          'id': 17,
          'egitimId': 3,
          'no': 1,
          'baslik': 'Temel — Nesne oklarını çiz',
        },
        {
          'id': 18,
          'egitimId': 3,
          'no': 2,
          'baslik': 'Temel — Sıralı tekilleştirme',
        },
      ],
    });
    expect(egitim.kod, 'PY-03');
    expect(egitim.gorevler.length, 2);
    expect(egitim.gorevler[1].no, 2);
    // Eksik alanlar varsayılan değerlerini alır.
    expect(egitim.baslangicKodu, '');
    expect(egitim.toJson()['gorevler'], hasLength(2));
  });
}
