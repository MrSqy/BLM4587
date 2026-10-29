import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

export 'src/aktarim.dart';

List<Directory> dersKlasorleriniBul(String depoYolu) {
  final dizin = Directory(p.join(depoYolu, 'dersler'));
  if (!dizin.existsSync()) {
    throw FileSystemException('Dersler klasörü bulunamadı.', dizin.path);
  }
  final desen = RegExp(r'^PY-(\d+)$');
  final dersler = dizin
      .listSync(followLinks: false)
      .whereType<Directory>()
      .where((d) => desen.hasMatch(p.basename(d.path)))
      .toList();
  dersler.sort((a, b) {
    final fark = int.parse(
      desen.firstMatch(p.basename(a.path))![1]!,
    ).compareTo(int.parse(desen.firstMatch(p.basename(b.path))![1]!));
    return fark != 0 ? fark : a.path.compareTo(b.path);
  });
  return dersler;
}

/// UTF-8 dosyalarını okur; Python dahil hiçbir kaynağı çalıştırmaz.
String metinOku(String yol) {
  try {
    return utf8.decode(File(yol).readAsBytesSync()).replaceAll('\r\n', '\n');
  } on FormatException {
    throw FormatException('$yol | Geçerli UTF-8 metin bekleniyor.');
  }
}
