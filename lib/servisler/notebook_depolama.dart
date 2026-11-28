import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../modeller/notebook.dart';

enum NotebookYerelKopya { kayit, taslak }

/// Örnek notebook'un kaydını ve çalışma taslağını uygulamanın dizininde tutar.
class NotebookDepolama {
  final Future<Directory> Function() dizinGetir;

  const NotebookDepolama({this.dizinGetir = getApplicationDocumentsDirectory});

  Future<File> _dosya(NotebookYerelKopya kopya) async {
    final dizin = await dizinGetir();
    return File('${dizin.path}/notebook/${kopya.name}.ipynb');
  }

  Future<NotebookBelgesi?> oku(NotebookYerelKopya kopya) async {
    final dosya = await _dosya(kopya);
    if (!await dosya.exists()) return null;
    return NotebookBelgesi.fromJsonString(await dosya.readAsString());
  }

  Future<void> yaz(NotebookYerelKopya kopya, NotebookBelgesi belge) async {
    final dosya = await _dosya(kopya);
    await dosya.parent.create(recursive: true);
    final geciciDizin = await dosya.parent.createTemp('.yaz-');
    try {
      final gecici = File('${geciciDizin.path}/notebook.ipynb');
      await gecici.writeAsString(belge.toJsonString(), flush: true);
      // Aynı dosya sisteminde yeniden adlandırma önceki kaydı yarım yazmaya karşı korur.
      await gecici.rename(dosya.path);
    } finally {
      await geciciDizin.delete(recursive: true);
    }
  }
}
