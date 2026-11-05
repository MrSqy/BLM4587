# Hafta 03 — Baran Demir

## Yaptıklarım

- 3.1: Ortak backend sözleşmesine uygun HTTP istemcisi; gerçek kayıt/giriş,
  kayıt sonrası otomatik oturum, 15 dakikalık oturumun güvenli saklanması ve çıkış.
  Refresh token yok. Süre bitimi/401 temizler; 403/429/503 oturumu korur.
  Gecikmiş eski 401 yanıtı yeni oturumu silmez. Bozuk/süresi geçmiş kayıt kullanılmaz.
- 3.2: Gerçek ders Markdown içeriği, Python metin editörü, 4 boşluk girintisi,
  çalıştır/test istekleri, çıktı/hata ve görev bazında sonuç kartları. Yalnız öğrenci
  kodu gönderilir. Tekrarlanan gönderim engellenir; zaman aşımı, başarısızlık,
  atlanan görev ve otomatik test yokluğu başarıdan ayrılır.
- Misafir erişimi sunucunun `misafireAcik` ve `erisilebilir` alanlarından alınır;
  ders sırasına/koduna göre tahmin yapılmaz. Kilitli derste yalnız özet ve giriş
  çağrısı gösterilir. Oturum kapandığında açık korunan ders içeriği kaldırılır.
- Ortak açık/koyu tema, Eğitimler/Profil/giriş/kayıt/ders ekranları ve ana sayfa
  uyumu. Ana sayfa kategorileri Eğitimler filtresini açar. Dört sekme korunur.
- Form alanları kaydırılsa bile birlikte doğrulanır. Hata yanıtlarında `{mesaj}`,
  ProblemDetails `title/errors` ve boş 401/403/429/503 gövdeleri desteklenir.
- Token ve kullanıcı kaydı güvenli depodadır; shared_preferences yalnız hassas
  olmayan `oturum_acik` bayrağını tutar. Parola/JWT imzalama anahtarı saklanmaz.
  Android yedeklemesi kapatıldı. HTTP yalnız debug; release istemcisi HTTPS ister.
- API adresi `API_ADRESI` ile belirlenir. Emülatör varsayılanı 10.0.2.2;
  fiziksel telefon için bilgisayarın erişilebilir adresi README'de açıklanmıştır.
- pubspec.lock mevcut Flutter SDK uyumlu çözümlemesini koruyarak HTTP, güvenli
  depolama ve tercihler bağımlılıklarını içerir. Yeni ağ kurulumu yapılmadı.

## Doğrulama — 2 Kasım 2026

- `flutter test --no-pub`: **64 test başarılı**. Form, misafir erişimi, oturum,
  süre dolması, HTTP hataları, güvenli depo adaptörü ve görev sonuçları dahil.
- `flutter analyze --no-pub`: **No issues found**.
- `flutter build bundle --debug --no-pub`: **başarılı**; Dart/Flutter debug bundle.
- `git diff --check`: başarılı.
- Geçici widget önizlemesi: açık/koyu Eğitimler ve giriş/kayıt ekranları,
  412×915 boyutta 4 başarılı render; görseller incelendi. Widget testlerinde
  ders ekranı 640×320 ve 2× yazıyla iki temada da taşmadan çalıştı.
- HTTP yanıtları ve güvenli depolama platform kanalı testlerde taklit edilir;
  gerçek API, Android Keystore veya cihaz kabulü olarak değerlendirilmez.

## Açık doğrulamalar / ortam engeli

- Android APK denemesi tamamen çevrimdışı yapıldı:
  `./gradlew --offline :app:assembleDebug -Ptarget=lib/main.dart -Ptarget-platform=android-arm64 -Pbuild-mode=debug`.
  `flutter_secure_storage` eklentisinin istediği
  `com.android.tools.build:gradle:8.5.1` yerel önbellekte yok; derleme bu aşamada
  durdu. Ağ kurulumu yapılmadı; APK derlemesi başarılı olarak raporlanamaz.
- Gerçek telefonda yeni görünüm, güvenli depolama, klavye ve API uçtan uca akışı
  henüz doğrulanmadı. Kullanıcıyla toplu debug kontrolü yapılacak.
- Backend sözleşmesine göre Python sandbox imajı eksik. Canlı Docker çalıştırma,
  test ve izolasyon kabulü bu Flutter çalışmasında yapılmadı.
- Backend yalnız salt okunur incelendi; birleştirilmiş JWT/controller/Program.cs
  veya backend proje dosyalarında bu devam çalışmasında değişiklik yapılmadı.
- Notebook modeli/görüntüleyici korunur. API derslerine notebook çıktılarının
  eşlenmesi ve kalıcı ilerleme/gönderim geçmişi bu teslimin kapsamında değildir.

## Commit / PR

- Flutter `baran` dalında yerel checkpoint; push ve PR kullanıcıya bırakıldı.
- Önceki `c3af85a` commit'i Hafta 02 küçük yatay ekran taşma düzeltmesidir.

## Kullanıcının çalıştıracağı dış adımlar

Android bağımlılıkları için ağ erişimiyle APK derleme (henüz yapılmadı):

```bash
cd /home/baranbeey/dev/BLM4587-proje
/home/baranbeey/flutter/bin/flutter build apk --debug --no-pub
```

Doğrulama sonrasında Flutter dalını gönderme:

```bash
cd /home/baranbeey/dev/BLM4587-proje
git push origin baran
```

## 6 Kasım 2026 — Görev bazlı v2 uyarlaması

- Backend'in GOREV_AKTARIMI_V2.md ve FLUTTER_DEVAM_PROMPTU.txt sözleşmeleri
  salt okunur incelendi. Backend dosyaları ve Nisa'nın tools/egitim_icerik aracı
  değiştirilmedi. Bu çalışma yalnız Flutter baran dalındadır.
- Gorev modeline tur, baslangicDosyasi, baslangicKodu ve tipli kontrol bilgisi;
  görev yanıtları için tipli GorevSonucu eklendi. Eksik tür eski-pytest kabul
  edilir; v2 çalışmış gibi gösterilmez.
- Görev seçimi, seçilen dosya/kod ve ders ID + gerçek görev ID anahtarlı bellek
  taslakları eklendi. Boş taslak korunur. Taslaklar görev geçişinde korunur;
  ders ekranı kapanınca/oturum değişince temizlenir, kalıcı taslak kaydı yoktur.
- Görev isteği URL'si gerçek ders ID ve görev NO kullanır; görev ID ile NO
  karıştırılmaz. Body yalnız {kod}; beklenen çıktı/girdi/dosya/kurallar gönderilmez.
  Ders düzeyindeki eski calistir/test uçları bu ekranda artık çağrılmaz.
- Açıklama görevinde Markdown/kabul ölçütleri gösterilir; editör, çalıştır/test
  veya otomatik başarılı etiketi yoktur. Eski-pytest, bilinmeyen/kontrolsüz görev
  için güncel içerik aktarımı mesajı ve yeniden yükleme seçeneği vardır.
- Çalıştır sonucu test başarısı değildir. Beklenen/gerçek stdout ve stderr
  trim/normalizasyon olmadan ayrı gösterilir. İsteğe bağlı JSON görünümü boşluk
  ve satır sonlarını açıklar. Null eşleşmeler değerlendirilemedi olarak sunulur.
  Çıkış kodu, sıfır dışındaki beklenen kod, kural ihlali, timeout ve çıktı limiti
  ayrı gösterilir. Başarı etiketi ancak sunucunun tutarlı başarılı testiyle gelir.
- Oturum değişiminde eski istek sonucu ekrana dönmez; devam eden gönderimde
  görev seçimi ve çift gönderim engellenir. 409 için açıklayıcı varsayılan mesaj
  eklendi; 403/409/429/503 yerel oturumu temizlemez.

Doğrulama:

- flutter analyze --no-pub: No issues found.
- flutter test --no-pub: 71 test başarılı. Model JSON turu, doğru görev dosyası,
  ID/NO ayrımı, taslak koruma, açıklama/legacy akışı, yalnız kod gönderimi,
  başarılı/başarısız çıktı ve exit, timeout/çıktı sınırı, misafir/üye, çıkış,
  401/403/409/429/503 ve iki temada büyük yazı regresyonları dahil.
- flutter build bundle --debug --no-pub: başarılı.
- git diff --check: başarılı.
- HTTP yanıtları ve oturum deposu testlerde taklittir. Gerçek Android APK,
  emülatör/telefon ve canlı v2 API/DB kabulü bu uyarlamada yapılmadı.
- Mevcut kullanıcı DB'sine migration ve PY-01 v2 aktarımı kullanıcı tarafından
  uygulanmalı. API'de 5 kod + 2 açıklama, yeni alanlar ve pasif eski 8'in
  yokluğu görülmeden gerçek içerikle uçtan uca tamamlandı kabul edilmeyecek.
- Ek veri/modül isteyen görevlerin paketlenmesi v2 dışında; destekleniyor
  iddiası yoktur. Backend PR birleştirmesi kullanıcı tarafından yürütülecek.
- Flutter yerel checkpoint commit; push/PR kullanıcıya bırakıldı. Ağ kurulumu yok.
