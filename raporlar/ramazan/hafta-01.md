# Hafta 01 — Ramazan Yalçın

**Ders:** BLM4587 · **Tarih:** 19–25 Ekim 2026 · **Lider:** Ramazan

## Özet

Bu hafta 1.4 işini tamamlayarak Jupyter nbformat 4 dosyalarını okuyup yazabilen tipli Dart modelini hazırladım. Ortak 1.5 işi kapsamında README'ye modelin kapsamını, test komutunu ve sonraki haftalara bırakılan özellikleri ekledim.

## 1.4 Jupyter notebook modeli

`lib/modeller/notebook.dart` içinde aşağıdaki yapılar eklendi:

- `NotebookBelgesi`: `nbformat`, `nbformat_minor`, notebook metadata'sı ve hücre listesi
- `MarkdownHucresi`, `KodHucresi`, `HamHucresi`
- `AkisCiktisi`: stdout/stderr metin çıktıları
- `GosterimCiktisi`: metin, görsel ve diğer MIME verileri
- `CalistirmaSonucu`: çalışma sayısı ve sonuç verileri
- `HataCiktisi`: hata adı, hata değeri ve traceback satırları

Model, çok satırlı `source` ve stream `text` değerlerini hem tek metin hem de metin listesi biçiminden okuyabiliyor. JSON yazarken bu alanları kararlı tek metin biçiminde üretiyor. Notebook/hücre metadata'sı, MIME map'leri, markdown/raw ekleri, hücre kimliği ve nullable çalışma sayısı JSON turunda korunuyor. nbformat 4.5 için hücre kimliği ve kod/sonuç çalışma sayısı alanlarının varlığı doğrulanırken daha eski nbformat 4 alt sürümleriyle uyumluluk korunuyor.

Eksik veya yanlış tipli zorunlu alanlar sessizce atlanmıyor. `cells[0].source` ve `cells[0].outputs[0].output_type` gibi alan yolunu taşıyan `FormatException` üretiliyor.

## 1.5 README katkısı

README'ye aşağıdaki bilgiler eklendi:

- İçerik aracı alt paketinin bağımlılık kurulum adımı
- Notebook modelinin dosya konumu
- Desteklenen hücre ve çıktı türleri
- Model testini çalıştırma komutu
- İlk hafta kapsamına girmeyen UI, dosya seçme ve hücre çalıştırma özellikleri

## Doğrulama sonuçları

Flutter 3.47.7 ve Dart 3.13.5 ile:

- `dart format --output=none --set-exit-if-changed lib test`: değişiklik gerekmiyor.
- `flutter analyze --no-pub`: sorun bulunmadı.
- `flutter test --no-pub`: toplam 26 test geçti.
- Notebook modeli: 17 test geçti.
- Önceden var olan uygulama/model testleri: 9 test geçti.

Yeni testler; üç hücre türünü, dört çıktı türünü ve tüm çıktı içeriklerini, String/liste biçimindeki çok satırlı alanları, metadata/MIME/ek turlarını, nullable çalışma sayısını, sürüme göre hücre kimliğini ve hatalı JSON alan yollarını kapsıyor.

## Commit'ler / PR

- `cc3c511` — Notebook ve hücre modelleri
- `44cf856` — Dört notebook çıktı türü
- `34df200` — Hatalı JSON için alan yollu doğrulama
- `00cb20b` — Ekler, nullable çalışma sayısı ve nbformat 4.5 kimlik doğrulaması
- PR: Henüz açılmadı; çalışma yerel `ramazan` dalındadır.

## Karşılaştığım sorunlar

- Bilgisayardaki varsayılan Flutter 3.38.5 / Dart 3.10.4, projenin Dart `^3.12.2` alt sınırını karşılamıyordu. Global kurulumu değiştirmeden Flutter 3.47.7 kullanan izole çalışma ortamında geliştirme ve test yaptım.
- Ana dizinden analiz çalıştırıldığında `tools/egitim_icerik` alt paketinin kendi bağımlılıkları kurulmamışsa import hataları oluşuyor. Alt pakette ayrıca `dart pub get` çalıştırılması gerektiğini README'ye ekledim.

## Bilinen sınırlar

- Model yalnızca bellekteki JSON metni veya map ile çalışıyor; cihazdan dosya seçme/kaydetme henüz yok.
- Notebook görüntüleme ve hücre çalıştırma arayüzleri bu haftanın kapsamında değildir.
- Bilinmeyen hücre veya çıktı türleri veri kaybını önlemek için `FormatException` ile reddediliyor.

## Gelecek hafta

- 2.4 işi kapsamında markdown ve kod hücrelerini salt okunur gösteren notebook ekranı hazırlanacak.
- Görüntüleyici bu haftaki tipli model üzerinden beslenecek.
