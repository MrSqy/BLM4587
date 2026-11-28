import 'dart:io';

import 'package:egitim_platformu/modeller/notebook.dart';
import 'package:egitim_platformu/servisler/notebook_depolama.dart';
import 'package:egitim_platformu/servisler/yerel_dosya_deposu.dart';
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

  test('önceki taslak yalnız aynı sunucu ve hesapta açılır', () async {
    const sunucu = 'https://egitim.example.test/api/mobil/';
    const hesap = 'ogrenci';
    final dosyalar = YerelDosyaDeposu(dizin: () async => dizin);
    final belge = NotebookBelgesi.fromJsonString(
      await File('assets/ornek_notebook.ipynb').readAsString(),
    );
    await dosyalar.yaz(
      'notebook-taslaklari',
      sunucu,
      hesap,
      'ornek.ipynb',
      belge.toJsonString(),
    );

    final ayniHesap = NotebookDepolama(
      dizinGetir: () async => dizin,
      sunucu: sunucu,
      hesap: hesap,
    );
    final baskaHesap = NotebookDepolama(
      dizinGetir: () async => dizin,
      sunucu: sunucu,
      hesap: 'baskasi',
    );
    final baskaSunucu = NotebookDepolama(
      dizinGetir: () async => dizin,
      sunucu: 'https://diger.example.test/',
      hesap: hesap,
    );

    expect(
      (await ayniHesap.oku(NotebookYerelKopya.taslak))?.toJson(),
      belge.toJson(),
    );
    expect(await ayniHesap.oku(NotebookYerelKopya.kayit), isNull);
    expect(await baskaHesap.oku(NotebookYerelKopya.taslak), isNull);
    expect(await baskaSunucu.oku(NotebookYerelKopya.taslak), isNull);

    final yeni = NotebookBelgesi.fromJsonString(
      '{"nbformat":4,"nbformat_minor":5,"metadata":{},"cells":[]}',
    );
    await ayniHesap.yaz(NotebookYerelKopya.taslak, yeni);
    expect(
      (await ayniHesap.oku(NotebookYerelKopya.taslak))?.toJson(),
      yeni.toJson(),
    );
  });
}
