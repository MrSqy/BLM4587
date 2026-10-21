import 'package:egitim_platformu/servisler/egitim_servisi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final servis = SahteEgitimServisi(gecikme: Duration.zero);

  test('kategoriler sıra numarasına göre gelir', () async {
    final kategoriler = await servis.kategorileriGetir();
    expect(kategoriler.map((k) => k.kisaltma), ['PY', 'TMA']);
  });

  test('dersler kategoriye göre süzülür', () async {
    expect(await servis.egitimleriGetir(kategoriId: 1), hasLength(3));
    expect(await servis.egitimleriGetir(kategoriId: 2), isEmpty);
  });

  test('her dersin sekiz görevi ve test kodu var', () async {
    final egitim = await servis.egitimGetir(1);
    expect(egitim, isNotNull);
    expect(egitim!.kod, 'PY-01');
    expect(egitim.gorevler.map((g) => g.no), [1, 2, 3, 4, 5, 6, 7, 8]);
    expect(egitim.testKodu, contains('def test_gorev_'));
  });

  test('olmayan ders için null döner', () async {
    expect(await servis.egitimGetir(999), isNull);
  });
}
