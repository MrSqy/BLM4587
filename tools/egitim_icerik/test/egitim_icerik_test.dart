import 'dart:io';

import 'package:egitim_icerik/egitim_icerik.dart';
import 'package:test/test.dart';

void main() {
  late Directory geciciDepo;

  setUp(() {
    geciciDepo = Directory.systemTemp.createTempSync('egitim_test_');
  });

  tearDown(() {
    geciciDepo.deleteSync(recursive: true);
  });

  test('Dersleri bulur, sayısal sıralar ve ilgisiz öğeleri eler', () {
    final derslerYolu = '${geciciDepo.path}${Platform.pathSeparator}dersler';

    for (final ad in ['PY-10', 'PY-2', 'PY-01', 'notlar', 'PY-abc']) {
      Directory(
        '$derslerYolu${Platform.pathSeparator}$ad',
      ).createSync(recursive: true);
    }

    // Adı uygun olsa da dosyalar ders klasörü sayılmamalı.
    File(
      '$derslerYolu${Platform.pathSeparator}PY-03',
    ).writeAsStringSync('örnek');

    final sonuc = dersKlasorleriniBul(geciciDepo.path);

    expect(sonuc.map((klasor) => klasor.path).toList(), [
      '$derslerYolu${Platform.pathSeparator}PY-01',
      '$derslerYolu${Platform.pathSeparator}PY-2',
      '$derslerYolu${Platform.pathSeparator}PY-10',
    ]);
  });

  test('Dersler klasörü yoksa hata verir', () {
    expect(
      () => dersKlasorleriniBul(geciciDepo.path),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('Dersler klasörü boşsa boş liste döndürür', () {
    Directory(
      '${geciciDepo.path}${Platform.pathSeparator}dersler',
    ).createSync();

    expect(dersKlasorleriniBul(geciciDepo.path), isEmpty);
  });
}
