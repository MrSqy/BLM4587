import 'dart:io';
import 'package:egitim_icerik/egitim_icerik.dart';

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln(
      'Kullanım: dart run bin/egitim_icerik.dart <egitim-klasoru>',
    );
    exitCode = 1;
    return;
  }

  try {
    final dersler = dersKlasorleriniBul(arguments.first);

    for (final ders in dersler) {
      stdout.writeln(ders.path);
    }

    stdout.writeln('Toplam ${dersler.length} ders bulundu.');
  } on FileSystemException catch (hata) {
    stderr.writeln('${hata.message} Yol: ${hata.path}');
    exitCode = 1;
  }
}
