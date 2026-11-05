import 'package:flutter_test/flutter_test.dart';
import 'package:egitim_platformu/modeller/gorev.dart';
import 'package:egitim_platformu/modeller/gorev_sonucu.dart';

void main() {
  test('v2 görev ve kontrol alanları boşlukları koruyarak JSON turu yapar', () {
    final j = <String, dynamic>{
      'id': 71,
      'egitimId': 9,
      'no': 3,
      'baslik': 'Selam',
      'aciklama': 'Ölçüt',
      'tur': 'kod',
      'baslangicDosyasi': 'gorevler/selam.py',
      'baslangicKodu': '# TODO\n',
      'kontrol': {
        'tur': 'standart-cikti',
        'beklenenCikti': '  Merhaba\n',
        'girdi': 'Ada\n',
        'beklenenCikisKodu': 2,
        'kullanilmamali': ['eval'],
      },
    };
    final g = Gorev.fromJson(j);
    expect(g.kodGorevi, isTrue);
    expect(g.toJson(), j);
  });
  test('test başarısı çıktı, exit ve kural alanlarıyla tutarlı olmalı', () {
    final j = <String, dynamic>{
      'no': 3,
      'basarili': true,
      'durum': 'basarili',
      'cikti': ' x\n',
      'hata': '',
      'cikisKodu': 2,
      'ciktiEslesiyor': true,
      'cikisKoduEslesiyor': true,
      'kuralIhlalleri': <String>[],
    };
    expect(GorevSonucu.fromJson(j).testGecti, isTrue);
    for (final alan in ['ciktiEslesiyor', 'cikisKoduEslesiyor']) {
      expect(GorevSonucu.fromJson({...j, alan: false}).testGecti, isFalse);
      expect(GorevSonucu.fromJson({...j, alan: null}).testGecti, isFalse);
    }
    expect(
      GorevSonucu.fromJson({
        ...j,
        'kuralIhlalleri': ['eval'],
      }).testGecti,
      isFalse,
    );
  });
}
