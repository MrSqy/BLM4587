import 'dart:io';

import 'package:egitim_platformu/modeller/notebook.dart';
import 'package:egitim_platformu/servisler/notebook_depolama.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dizin;
  NotebookDepolama olustur() => NotebookDepolama(dizinGetir: () async => dizin);

  setUp(() async {
    dizin = await Directory.systemTemp.createTemp('notebook-test-');
  });
  tearDown(() async => dizin.delete(recursive: true));

  test('kayıt ve taslak farklı oturumlarda ayrı ayrı okunur', () async {
    final depolama = olustur();
    expect(await depolama.oku(NotebookYerelKopya.kayit), isNull);
    expect(await depolama.oku(NotebookYerelKopya.taslak), isNull);

    final ornek = NotebookBelgesi.fromJsonString(
      await File('assets/ornek_notebook.ipynb').readAsString(),
    );
    const taslakJson =
        '{"nbformat":4,"nbformat_minor":5,"metadata":{},"cells":'
        '[{"id":"taslak","cell_type":"markdown","metadata":{},"source":"# Çalışma"}]}';
    final taslak = NotebookBelgesi.fromJsonString(taslakJson);

    await depolama.yaz(NotebookYerelKopya.kayit, ornek);
    await depolama.yaz(NotebookYerelKopya.taslak, taslak);

    final yeniOturum = olustur();
    final kayit = await yeniOturum.oku(NotebookYerelKopya.kayit);
    expect(kayit?.toJson(), ornek.toJson());
    expect(
      (await yeniOturum.oku(NotebookYerelKopya.taslak))?.hucreler.single.kaynak,
      '# Çalışma',
    );

    await yeniOturum.yaz(NotebookYerelKopya.kayit, taslak);
    expect(
      (await olustur().oku(NotebookYerelKopya.kayit))?.hucreler.single.id,
      'taslak',
    );
  });

  test(
    'bozuk taslak kaydın açılmasını engellemez ve üzerine yazılabilir',
    () async {
      final depolama = olustur();
      final ornek = NotebookBelgesi.fromJsonString(
        await File('assets/ornek_notebook.ipynb').readAsString(),
      );
      await depolama.yaz(NotebookYerelKopya.kayit, ornek);
      await depolama.yaz(NotebookYerelKopya.taslak, ornek);
      final taslak =
          await dizin
                  .list(recursive: true)
                  .where(
                    (girdi) =>
                        girdi is File && girdi.path.endsWith('taslak.ipynb'),
                  )
                  .single
              as File;
      await taslak.writeAsString('{');

      await expectLater(
        depolama.oku(NotebookYerelKopya.taslak),
        throwsFormatException,
      );
      expect(
        (await depolama.oku(NotebookYerelKopya.kayit))?.toJson(),
        ornek.toJson(),
      );
      await depolama.yaz(NotebookYerelKopya.taslak, ornek);
      expect(
        (await depolama.oku(NotebookYerelKopya.taslak))?.toJson(),
        ornek.toJson(),
      );
    },
  );
}
