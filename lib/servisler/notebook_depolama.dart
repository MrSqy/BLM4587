import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../modeller/notebook.dart';
import 'yerel_dosya_deposu.dart';

enum NotebookYerelKopya { kayit, taslak }

class NotebookDepolama {
  final Future<Directory> Function() dizinGetir;
  final String sunucu;
  final String? hesap;

  const NotebookDepolama({
    this.dizinGetir = getApplicationSupportDirectory,
    this.sunucu = '',
    this.hesap,
  });

  YerelDosyaDeposu get _dosyalar => YerelDosyaDeposu(dizin: dizinGetir);

  Future<NotebookBelgesi?> oku(NotebookYerelKopya kopya) async {
    var ham = await _dosyalar.oku(
      'notebooklar',
      sunucu,
      hesap,
      '${kopya.name}.ipynb',
    );
    if (ham == null && kopya == NotebookYerelKopya.taslak) {
      ham = await _dosyalar.oku(
        'notebook-taslaklari',
        sunucu,
        hesap,
        'ornek.ipynb',
      );
    }
    return ham == null ? null : NotebookBelgesi.fromJsonString(ham);
  }

  Future<void> yaz(NotebookYerelKopya kopya, NotebookBelgesi belge) =>
      _dosyalar.yaz(
        'notebooklar',
        sunucu,
        hesap,
        '${kopya.name}.ipynb',
        belge.toJsonString(),
      );
}
