import 'dart:io';
import 'package:egitim_icerik/egitim_icerik.dart';

void main(List<String> arguments) {
  const yardim =
      'Kullanım: dart run bin/egitim_icerik.dart <kaynak-klasoru> <cikti.json>\n'
      'Yalnız kaynak verilirse dersleri listeler. --help: bu yardım. Python çalıştırılmaz.';
  if (arguments.length == 1 && {'--help', '-h'}.contains(arguments.first)) {
    stdout.writeln(yardim);
    return;
  }
  if (arguments.isEmpty ||
      arguments.length > 2 ||
      arguments.any((a) => a.startsWith('--'))) {
    stderr.writeln(yardim);
    exitCode = 1;
    return;
  }
  try {
    if (arguments.length == 1) {
      final dersler = dersKlasorleriniBul(arguments.first);
      for (final ders in dersler) {
        stdout.writeln(ders.path);
      }
      stdout.writeln('Toplam ${dersler.length} ders bulundu.');
      return;
    }
    final veri = egitimleriAktar(arguments.first);
    jsonYaz(arguments.first, arguments[1], veri);
    final dersler = veri['egitimler'] as List;
    var gorev = 0;
    var test = 0;
    var kontrol = 0;
    for (final ders in dersler) {
      gorev += (ders['gorevler'] as List).length;
      test += (ders['testler'] as List).length;
      kontrol += (ders['gorevler'] as List)
          .where((dynamic g) => g['kontrol'] != null)
          .length;
    }
    for (final uyari in veri['uyarilar'] as List) {
      stderr.writeln('Uyarı: $uyari');
    }
    stdout.writeln(
      '${dersler.length} ders, $gorev görev, $test test_gorev_N tanımı, $kontrol çıktı kontrolü. JSON: ${arguments[1]}',
    );
  } on FileSystemException catch (hata) {
    stderr.writeln('${hata.message} Yol: ${hata.path}');
    exitCode = 1;
  } on FormatException catch (hata) {
    stderr.writeln('İçerik hatası: ${hata.message}');
    exitCode = 1;
  }
}
