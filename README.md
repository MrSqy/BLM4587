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

## 3. hafta: mobil API, oturum ve kod çalışması

- Sade lacivert açık/koyu tema; Eğitimler, Profil, giriş/kayıt ve ders/kod ekranları.
  Ana sayfa kategori kartı ilgili eğitim filtresini açar. Mevcut dört sekme korunur.
- Veriler artık HTTP üzerinden BLM4581 `/api/mobil/` uçlarından gelir.
  Sahte servis yalnız test/örnek veridir; bağlantı hatasında sessizce sahte veriye geçilmez.
- Misafir erişiminde sunucunun `misafireAcik` ve `erisilebilir` alanları kullanılır.
  Her kategorinin ilk dersi okunabilir, çalıştırılabilir ve test edilebilir.
  Diğer derslerde özet ve giriş çağrısı gösterilir. Erişimi backend de denetler.
- Kayıt sonrası otomatik oturum açılır. Şifre en az 8 karakter; büyük/küçük harf,
  rakam ve özel karakter içerir. JWT ömrü 15 dakika, refresh token yoktur.
- Token, bitiş ve kullanıcı bilgileri `flutter_secure_storage` içinde saklanır;
  `shared_preferences` yalnız `oturum_acik` boolean değerini taşır. Parola saklanmaz.
  Android yedeklemesi kapalıdır. Süre bitimi/401 oturumu temizler; 403/409/429/503 temizlemez.
  Başarılı çıkış backend'de hesabın eski JWT'lerini iptal eder, cihaz kaydını siler.
  Ağ hatasıyla başarısız çıkış, başarı gibi gösterilmez.
- Kod editörü 32000 karakter sınırı ve girinti düğmesi içerir. Görev seçimiyle her görevin kendi başlangıç dosyası/kodu açılır.
  Taslaklar gerçek ders ID + görev ID anahtarlarıyla bu açık ders ekranı boyunca
  korunur. Oturum süresi dolduğunda misafire açık derste editör taslağıyla açılır.
  Korunan derste aynı hesapla tekrar giriş yapılınca taslak geri gelir.
  Farklı hesapların taslakları ayrı tutulur. Ekran kapatılınca bellekteki taslaklar silinir.
  Çalıştır ve Test et yalnız öğrenci kodunu görev numaralı v2 endpoint'e gönderir.
  Açıklama görevlerinde editör/otomatik test yoktur. Eski pytest veya kontrolsüz
  görevlerde aktarım gerekli mesajı gösterilir; eski ders endpoint'leri çağrılmaz.
  Gerçek/beklenen stdout ve çıkış kodu ayrı gösterilir; boşluk ve son satır sonu
  korunur. İsteğe bağlı JSON görünümü görünmez karakterleri açığa çıkarır.
  Çalıştırma bir test başarısı değildir. Zaman aşımı, çıktı sınırı, kural ihlali ve
  eşleşme alanlarının null olması başarısız/değerlendirilemedi olarak sunulur.
- `{mesaj}`, ProblemDetails `title/errors` ve boş HTTP hata yanıtları desteklenir.
  Notebook modeli ve görüntüleyici bileşeni korunur; API dersleri gerçek Markdown
  içeriğini gösterir, her ders yerine aynı örnek notebook açılmaz.

### Gönderim geçmişi (4.1)

İlerleme sekmesi, oturum sahibinin son gönderimlerini ve kod/çıktı ayrıntısını
`GET /api/gonderimler` ve `GET /api/gonderimler/{id}` uçlarından alır.
Liste sayfalıdır ve sekmeye dönünce yenilenir. Bu uçlar `/api/mobil` altında
değildir. Backend'de `GonderimGecmisi` migration'ı uygulanmış olmalıdır.
Bu sürümün İlerleme sekmesi gönderim geçmişini gösterir. Ders tamamlama oranı
5.1 API’siyle bağlanacaktır.

Çalıştır ve Test et istekleri varsayılan olarak 60 saniye bekler. Bu süre
4.4 kuyruğunun 15 saniye bekleme, 30 saniye işlem sınırı ve 15 saniye yanıt
payını kapsar. Sunucu sınırları değişirse mobil derlemede
`--dart-define=KOD_ZAMAN_ASIMI_SANIYE=<saniye>` ile ayarlayın.
Diğer istekler mevcut 20 saniyelik süreyi kullanır.

### Görev bazlı v2 içerik önkoşulu

Backend'de görev şeması migration'ı ve v2 PY-01 aktarımı kullanıcı tarafından
uygulanmalıdır. Yalnız kodu güncellemek eski DB'yi dönüştürmez. Ayrıntılar BLM4581
`docs/GOREV_AKTARIMI_V2.md` belgesindedir. Mobil detayda 1–5 kod ve 6–7 açıklama,
`tur`, `baslangicDosyasi`, `baslangicKodu`, `kontrol` alanları görülmelidir.
Görev 8 pasif olmalı ve mobil yanıtta gelmemelidir. Desteklenen çalışma biçimi
bağımsız Python programı ve sunucuda kayıtlı stdin/stdout kontrolüdür; ek modül/veri
paketi gerektiren dersler bu sözleşmeyle eksiksiz çalışır kabul edilmez.
Nisa'nın `tools/egitim_icerik` üreticisi bu değişiklikte düzenlenmedi.

### API adresi ve yerel çalıştırma

Android emülatöründe varsayılan adres `http://10.0.2.2:5080/api/mobil/`;
Android dışı geliştirme ortamında `http://127.0.0.1:5080/api/mobil/`.
Fiziksel telefonda `127.0.0.1` telefonun kendisidir. Bilgisayarla aynı yerel ağdaki
telefon için bilgisayarın erişilebilir IPv4 adresini açıkça verin:

```bash
cd /home/baranbeey/dev/BLM4587-proje
read 'BLM_API_HOST?Bilgisayarın telefondan erişilebilir IPv4 adresi: '
/home/baranbeey/flutter/bin/flutter run --debug --no-pub --dart-define="API_ADRESI=http://${BLM_API_HOST}:5080/api/mobil/"
unset BLM_API_HOST
```

Backend'in yalnız localhost yerine bu arayüzden erişilebilir dinlemesi gerekir;
backend ortamı ve Docker hazırlığı .NET çalışmasının sorumluluğundadır.
Adresin sonundaki `/` isteğe bağlıdır. HTTP yalnız debug geliştirmesinde açıktır;
yayın derlemesinde API adresi HTTPS olmalıdır. JWT anahtarı ve parolaları
Flutter'a, dart-define parametrelerine veya depoya eklemeyin.

### Yerel doğrulama

```bash
/home/baranbeey/flutter/bin/flutter test --no-pub
/home/baranbeey/flutter/bin/flutter analyze --no-pub
/home/baranbeey/flutter/bin/flutter build bundle --debug --no-pub
```

Android bağımlılıkları önbellekteyse, ağ kullanmadan APK kontrolü:

```bash
cd android
./gradlew --offline :app:assembleDebug -Ptarget=lib/main.dart -Ptarget-platform=android-arm64 -Pbuild-mode=debug
```

Widget/HTTP testleri taklit yanıtlar ve depolama kanalı kullanır; gerçek backend,
Android Keystore, Docker izolasyonu veya telefon kabulü yerine geçmez.
Bu teslimin sonuçları ve eksik ortam bağımlılığı `raporlar/baran/hafta-03.md` içindedir.

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

Hafta 01 modeli ve Hafta 02 salt okunur notebook bileşeni korunur. Hafta 03 API ders ekranı Markdown ve Python editörü kullanır; notebook çıktılarının API üzerinden eşlenmesi ayrı backend/görüntüleyici çalışmasıdır.

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
