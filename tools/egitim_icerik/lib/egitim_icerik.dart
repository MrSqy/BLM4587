import 'dart:convert';
import 'dart:io';
import 'src/kaynak_duzeni.dart';

export 'src/aktarim.dart';

List<Directory> dersKlasorleriniBul(String depoYolu) {
  return KaynakDuzeni(depoYolu).klasorler();
}

/// UTF-8 dosyalarını okur; Python dahil hiçbir kaynağı çalıştırmaz.
String metinOku(String yol) {
  try {
    return utf8.decode(File(yol).readAsBytesSync()).replaceAll('\r\n', '\n');
  } on FormatException {
    throw FormatException('$yol | Geçerli UTF-8 metin bekleniyor.');
  }
}
