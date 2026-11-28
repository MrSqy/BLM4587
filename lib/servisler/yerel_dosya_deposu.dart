import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class YerelDosyaDeposu {
  final Future<Directory> Function() dizin;
  const YerelDosyaDeposu({this.dizin = getApplicationSupportDirectory});

  Future<Directory> _klasor(String klasor, String sunucu, String? hesap) async {
    final anahtar = base64Url.encode(utf8.encode(jsonEncode([sunucu, hesap])));
    final temel = await dizin();
    return Directory(
      [temel.path, klasor, anahtar].join(Platform.pathSeparator),
    );
  }

  Future<File> _dosya(
    String klasor,
    String sunucu,
    String? hesap,
    String ad,
  ) async {
    final dizin = await _klasor(klasor, sunucu, hesap);
    return File('${dizin.path}${Platform.pathSeparator}$ad');
  }

  Future<List<File>> dosyalariListele(
    String klasor,
    String sunucu,
    String hesap,
  ) async {
    final dizin = await _klasor(klasor, sunucu, hesap);
    if (!await dizin.exists()) return [];
    return dizin
        .list(followLinks: false)
        .where((girdi) => girdi is File)
        .cast<File>()
        .toList();
  }

  Future<String?> oku(
    String klasor,
    String sunucu,
    String? hesap,
    String ad,
  ) async {
    final dosya = await _dosya(klasor, sunucu, hesap, ad);
    if (!await dosya.exists()) return null;
    return dosya.readAsString();
  }

  Future<void> yaz(
    String klasor,
    String sunucu,
    String? hesap,
    String ad,
    String veri,
  ) async {
    final dosya = await _dosya(klasor, sunucu, hesap, ad);
    await dosya.parent.create(recursive: true);
    final geciciDizin = await dosya.parent.createTemp('.kayit-');
    try {
      final gecici = File('${geciciDizin.path}${Platform.pathSeparator}veri');
      await gecici.writeAsString(veri, flush: true);
      await gecici.rename(dosya.path);
    } finally {
      await geciciDizin.delete(recursive: true);
    }
  }
}

const yerelDosyaDeposu = YerelDosyaDeposu();
