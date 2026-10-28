# BLM4587 — Etkileşimli Eğitim Platformu (Android Uygulaması)

Flutter (Android) uygulaması ve Dart içerik aracı. BLM4581 deposundaki Web API'yi kullanır.

Ekip: Ramazan, Nisa, Baran

## Gereksinimler

- Flutter 3.44 veya üstü (Dart 3.12+), `flutter doctor` ile Android toolchain kurulu olmalı
- Android telefon (USB hata ayıklama açık) veya emülatör

> Projeyi Türkçe karakter ve boşluk içermeyen bir klasöre klonlayın
> (ör. `~/dev/BLM4587` veya `C:\dev\BLM4587`). Aksi hâlde Android derlemesi hata verebilir.

## Kurulum

```bash
flutter pub get
flutter run
```

Testler ve kod analizi:

```bash
flutter analyze
flutter test
```

## 2. hafta: giriş/kayıt formları ve eğitim listesi

- Uygulama misafir olarak açılır. **Profil → Giriş yap / Kayıt ol** ile demo formlarına ulaşılır.
- Girişte e-posta ve şifre; kayıtta ayrıca ad soyad ve şifre tekrarı zorunludur.
  E-posta biçimi, en az 8 karakterlik şifre ve şifre eşleşmesi kontrol edilir.
- Geçerli form yalnızca demo bildirimi gösterir: hesap oluşturulmaz, kimlik doğrulanmaz,
  oturum açılmaz ve bilgiler kaydedilmez. Gerçek API/JWT bağlantısı 3. haftanın işidir.
- **Eğitimler** sekmesinde kategori kartları ve ders listesi bulunur. Kart seçilince
  liste filtrelenir; **Tümü** tüm dersleri getirir. Veriler mevcut sahte veri servisindendir.
- Boş liste ve yükleme hatası için mesaj, hata durumunda **Tekrar dene** düğmesi vardır.
  Ders satırları bu hafta başlık, ders kodu ve görev sayısını gösterir; ders içeriği
  görüntüleyicisi bu değişikliğin kapsamında değildir.

Kontrol etmek için:

```bash
flutter test --no-pub
flutter analyze --no-pub
```

## İçerik aracı

`tools/egitim_icerik` ayrı bir Dart paketidir. Ayrıntılar için kendi README dosyasına bakın.

Ana projeyle birlikte analiz çalıştırmadan önce bu alt paketin bağımlılıklarını da kurun:

```bash
(cd tools/egitim_icerik && dart pub get)
```

## Jupyter notebook modeli

`lib/modeller/notebook.dart`, Jupyter nbformat 4 JSON belgelerini tipli Dart nesnelerine dönüştürür ve yeniden JSON üretir.

Desteklenen yapı:

- Üst alanlar: `nbformat`, `nbformat_minor`, `metadata`, `cells`
- Hücreler: `markdown`, `code`, `raw`
- Kod çıktıları: `stream`, `display_data`, `execute_result`, `error`
- `source` ve stream `text` alanlarında hem tek metin hem metin listesi
- MIME verileri, markdown/raw ekleri, hücre/notebook metadata alanları, hücre kimliği ve nullable çalışma sayısı
- nbformat 4.5 ve sonrasında zorunlu hücre kimliği doğrulaması; eski nbformat 4 alt sürümleriyle kimliksiz hücre uyumluluğu
- Hatalı zorunlu alanlarda alan yolunu belirten `FormatException`

Örnek nbformat belgesi ve model testleri `test/fixtures/ornek_notebook.ipynb` ile `test/notebook_modeli_test.dart` dosyalarındadır.

```bash
flutter test test/notebook_modeli_test.dart
```

Hafta 01 kapsamı yalnızca JSON modeli ve dönüşümleridir. Notebook dosyası seçme/kaydetme, salt okunur görüntüleme, hücre düzenleme ve çalıştırma arayüzleri henüz eklenmemiştir.

## Klasör yapısı

```
lib/                     Uygulama kodu
  modeller/notebook.dart Jupyter nbformat 4 modeli
test/                    Widget ve birim testleri
  fixtures/              Test notebook dosyaları
android/                 Android projesi
tools/egitim_icerik/     İçerik aracı (Dart komut satırı paketi)
```

## Çalışma düzeni

- `main` korumalıdır; doğrudan push yapılamaz, değişiklikler yalnızca pull request ile girer.
- Her üyenin kendi dalı vardır: `baran`, `nisa`, `ramazan`. Herkes kendi dalında, kendi GitHub hesabıyla commit atar.
- Bir işi bitirince kendi dalından `main`'e pull request açın. Birleştirme yöntemi "Create a merge commit"tir;
  böylece her commit kendi yazarı ve tarihiyle `main`'de görünür.
- Başkasının işinin üzerine çalışmadan önce `main`'i kendi dalınıza alın:

  ```bash
  git switch <adiniz>
  git pull
  git fetch origin
  git merge origin/main
  ```

- Her hafta `raporlar/<adiniz>/hafta-NN.md` dosyasına kısa bir rapor yazın (şablon: [raporlar/README.md](raporlar/README.md)).
