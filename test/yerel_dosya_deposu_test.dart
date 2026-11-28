import 'dart:io';

import 'package:egitim_platformu/modeller/notebook.dart';
import 'package:egitim_platformu/servisler/ders_notu_deposu.dart';
import 'package:egitim_platformu/servisler/yerel_dosya_deposu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dizin;
  late YerelDosyaDeposu dosyalar;
  const sunucu = 'http://localhost:5080/api/mobil/';

  setUp(() async {
    dizin = await Directory.systemTemp.createTemp('blm4587-yerel-test-');
    dosyalar = YerelDosyaDeposu(dizin: () async => dizin);
  });

  tearDown(() async => dizin.delete(recursive: true));

  test(
    'not ve yer imi yeniden açılır, hesap/sunucu/ders arasında ayrılır',
    () async {
      final depo = DersNotuDeposu(dosyalar: dosyalar);
      await depo.yaz(
        sunucu,
        'ogrenci-a',
        1,
        const DersNotu(metin: 'İlk not', yerImi: true),
      );
      final yeniDepo = DersNotuDeposu(
        dosyalar: YerelDosyaDeposu(dizin: () async => dizin),
      );
      final kayit = await yeniDepo.oku(sunucu, 'ogrenci-a', 1);
      expect(kayit.metin, 'İlk not');
      expect(kayit.yerImi, isTrue);
      expect((await depo.oku(sunucu, 'ogrenci-b', 1)).metin, isEmpty);
      expect((await depo.oku(sunucu, 'ogrenci-a', 2)).yerImi, isFalse);
      expect(
        (await depo.oku('https://other.invalid', 'ogrenci-a', 1)).yerImi,
        isFalse,
      );

      await depo.yaz(
        sunucu,
        'ogrenci-a',
        1,
        const DersNotu(metin: 'Düzenlenen not'),
      );
      expect(
        (await depo.liste(sunucu, 'ogrenci-a'))[1]?.metin,
        'Düzenlenen not',
      );
      await depo.yaz(sunucu, 'ogrenci-a', 1, const DersNotu());
      expect(await depo.liste(sunucu, 'ogrenci-a'), isEmpty);
    },
  );

  test(
    'notebook taslağı .ipynb olarak yeniden açılır ve misafir ayrıdır',
    () async {
      final belge = NotebookBelgesi.fromJson({
        'nbformat': 4,
        'nbformat_minor': 5,
        'metadata': {
          'language_info': {'name': 'python'},
        },
        'cells': [
          {
            'cell_type': 'markdown',
            'id': 'giris',
            'metadata': {},
            'source': '# Taslak',
          },
        ],
      });
      await dosyalar.yaz(
        'notebook-taslaklari',
        sunucu,
        'ogrenci-a',
        'ornek.ipynb',
        belge.toJsonString(),
      );
      final acilan = (await dosyalar.oku(
        'notebook-taslaklari',
        sunucu,
        'ogrenci-a',
        'ornek.ipynb',
      ))!;
      expect(NotebookBelgesi.fromJsonString(acilan).toJson(), belge.toJson());
      expect(
        await dosyalar.oku('notebook-taslaklari', sunucu, null, 'ornek.ipynb'),
        isNull,
      );
    },
  );
}
