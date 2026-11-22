import 'dart:math';

import 'package:flutter/foundation.dart';

import 'notebook.dart';

enum YeniHucreTuru { kod, markdown }

/// Silinen hücreyi geri almak için gereken bilgi.
class SilinenHucre {
  final int indeks;
  final NotebookHucresi hucre;
  final int anahtar;

  const SilinenHucre._(this.indeks, this.hucre, this.anahtar);
}

/// 4.3: Notebook hücrelerini bellekte düzenler (ekle, sil, taşı, kaynak değiştir).
/// [NotebookBelgesi] değişmez kalır; güncel hâl [belge] ile alınır. Cihaza kaydetme 5.3'tür.
///
/// Her hücrenin, yeri değişse de aynı kalan bir [anahtar]ı vardır. Ekran metin
/// denetleyicilerini bu anahtarla tutar; nbformat 4.5 öncesinde hücre kimliği olmadığı için gerekir.
class NotebookDuzenleyici extends ChangeNotifier {
  final NotebookBelgesi _ozgun;
  final Random _rastgele;
  final List<NotebookHucresi> _hucreler;
  final List<int> _anahtarlar;
  int _sonrakiAnahtar;
  bool _degisti = false;

  NotebookDuzenleyici(NotebookBelgesi belge, {Random? rastgele})
    : _ozgun = belge,
      _rastgele = rastgele ?? Random.secure(),
      _hucreler = List<NotebookHucresi>.of(belge.hucreler),
      _anahtarlar = List<int>.generate(belge.hucreler.length, (i) => i),
      _sonrakiAnahtar = belge.hucreler.length;

  List<NotebookHucresi> get hucreler => List.unmodifiable(_hucreler);
  int get uzunluk => _hucreler.length;
  bool get degisti => _degisti;

  int anahtar(int indeks) => _anahtarlar[indeks];

  /// Anahtarın şu anki indeksi; hücre silinmişse -1.
  int anahtarIndeksi(int anahtar) => _anahtarlar.indexOf(anahtar);

  NotebookBelgesi get belge => NotebookBelgesi(
    nbformat: _ozgun.nbformat,
    nbformatMinor: _ozgun.nbformatMinor,
    metadata: _ozgun.metadata,
    hucreler: _hucreler,
  );

  /// [indeks] konumuna boş bir hücre ekler; yeni hücrenin indeksini döndürür.
  int ekle(int indeks, YeniHucreTuru tur) {
    RangeError.checkValueInInterval(indeks, 0, _hucreler.length, 'indeks');
    final id = _yeniKimlik();
    final NotebookHucresi hucre = switch (tur) {
      YeniHucreTuru.kod => KodHucresi(
        id: id,
        metadata: const {},
        kaynak: '',
        calistirmaSayisi: null,
        ciktilar: const [],
      ),
      YeniHucreTuru.markdown => MarkdownHucresi(
        id: id,
        metadata: const {},
        kaynak: '',
        ekler: const {},
      ),
    };
    _hucreler.insert(indeks, hucre);
    _anahtarlar.insert(indeks, _sonrakiAnahtar++);
    _degistir();
    return indeks;
  }

  SilinenHucre sil(int indeks) {
    RangeError.checkValidIndex(indeks, _hucreler, 'indeks');
    final silinen = SilinenHucre._(
      indeks,
      _hucreler.removeAt(indeks),
      _anahtarlar.removeAt(indeks),
    );
    _degistir();
    return silinen;
  }

  /// Silinen hücreyi eski yerine (liste kısaldıysa sona) aynı anahtarla geri koyar.
  void geriAl(SilinenHucre silinen) {
    if (_anahtarlar.contains(silinen.anahtar)) return;
    final indeks = min(silinen.indeks, _hucreler.length);
    _hucreler.insert(indeks, silinen.hucre);
    _anahtarlar.insert(indeks, silinen.anahtar);
    _degistir();
  }

  /// Hücreyi [eski] konumundan alıp son konumu [yeni] olacak şekilde yerleştirir.
  void tasi(int eski, int yeni) {
    RangeError.checkValidIndex(eski, _hucreler, 'eski');
    RangeError.checkValidIndex(yeni, _hucreler, 'yeni');
    if (eski == yeni) return;
    _hucreler.insert(yeni, _hucreler.removeAt(eski));
    _anahtarlar.insert(yeni, _anahtarlar.removeAt(eski));
    _degistir();
  }

  void kaynakGuncelle(int indeks, String kaynak) {
    RangeError.checkValidIndex(indeks, _hucreler, 'indeks');
    if (_hucreler[indeks].kaynak == kaynak) return;
    _hucreler[indeks] = _hucreler[indeks].kaynakIle(kaynak);
    _degistir();
  }

  void _degistir() {
    _degisti = true;
    notifyListeners();
  }

  // nbformat 4.5 ve sonrası her hücrede benzersiz kimlik ister; öncesinde kimlik yazılmaz.
  String? _yeniKimlik() {
    if (_ozgun.nbformat < 4 ||
        (_ozgun.nbformat == 4 && _ozgun.nbformatMinor < 5)) {
      return null;
    }
    final kullanilan = _hucreler.map((h) => h.id).toSet();
    String id;
    do {
      id = List.generate(
        8,
        (_) => _rastgele.nextInt(16).toRadixString(16),
      ).join();
    } while (kullanilan.contains(id));
    return id;
  }
}
