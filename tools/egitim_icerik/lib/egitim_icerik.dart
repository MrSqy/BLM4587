import 'dart:io';

List<Directory> dersKlasorleriniBul(String depoYolu) {
  final derslerDizini = Directory('$depoYolu${Platform.pathSeparator}dersler');

  if (!derslerDizini.existsSync()) {
    throw FileSystemException(
      'Dersler klasörü bulunamadı.',
      derslerDizini.path,
    );
  }

  final dersDeseni = RegExp(r'^PY-(\d+)$');

  final dersler = derslerDizini
      .listSync(followLinks: false)
      .whereType<Directory>()
      .where((klasor) {
        final ad = klasor.uri.pathSegments
            .where((parca) => parca.isNotEmpty)
            .last;
        return dersDeseni.hasMatch(ad);
      })
      .toList();

  int dersNumarasi(Directory klasor) {
    final ad = klasor.uri.pathSegments.where((parca) => parca.isNotEmpty).last;
    return int.parse(dersDeseni.firstMatch(ad)!.group(1)!);
  }

  dersler.sort((a, b) => dersNumarasi(a).compareTo(dersNumarasi(b)));

  return dersler;
}
