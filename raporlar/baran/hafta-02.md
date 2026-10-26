# Hafta 02 — Baran Demir

**Ders:** BLM4587 · **Hafta:** 26 Ekim–1 Kasım 2026 · **Lider:** Ramazan
**Bu rapordaki doğrulama tarihi:** 26 Ekim 2026

## Yaptıklarım

- **2.1 Giriş ve kayıt ekranları:** Profil'den açılan isimli rotalar, `Form` ve
  `TextFormField` doğrulamaları eklendi. Girişte e-posta/şifre; kayıtta ayrıca
  ad soyad/şifre tekrarı bulunur. Boş alanlar, e-posta biçimi, en az 8 karakterlik
  şifre ve şifre eşleşmesi kontrol edilir. Şifre göster/gizle düğmesi vardır.
- Misafir kullanım devam eder. Geçerli form açıkça demo bildirimi gösterir;
  hesap oluşturulmaz, oturum açılmaz ve bilgiler kaydedilmez.
- **2.2 Eğitim listesi ve kategoriler:** `GridView.builder` kategori kartları ile
  `ListView.builder` ders listesi eklendi. Seçilen kategori listeyi filtreler;
  Tümü seçeneği filtreyi kaldırır. Kartlarda ders sayısı ve seçim işareti,
  derslerde başlık, kod ve görev sayısı gösterilir.
- Veriler mevcut `EgitimServisi` üzerinden yüklenir. Filtreleme bellekte yapılır;
  filtre değişiminde yeni servis isteği oluşmaz. Yükleniyor, boş liste, hata ve
  tekrar deneme durumları eklendi. Kartlar ekran genişliği/yazı boyutuna uyarlanır.
- README'ye yeni ekranların kullanım adımları ve demo sınırları eklendi.

## Doğrulama

Flutter 3.44.9 / Dart 3.12.2 ile:

- `flutter test --no-pub`: **18 test geçti** (önceki 9 teste ek 5 form ve 4 liste testi).
- `flutter analyze --no-pub`: sorun bulunmadı.
- `git diff --check`: sorun bulunmadı.
- Form testleri: boş/geçersiz giriş, geçerli demo giriş/kayıt, eşleşmeyen şifre,
  şifre görünürlüğü, rota geçişi ve misafir olarak geri dönüş.
- Liste testleri: kategori/Tümü filtresi, ek istek oluşmaması, boş kategori/liste,
  yükleniyor/hata/tekrar deneme, 360 piksel genişlikte iki kat yazı boyutu.

Bunlar otomatik widget ve birim testleridir. Fiziksel telefon/emülatör üzerinde
manuel deneme ve Android APK derlemesi bu çalışmada yapılmadı. İçerik aracı alt
paketinin testleri bu sayıya dahil değildir.

## Commit'ler / PR

- `29e1a94` — 2.1 Demo giriş ve kayıt formları ile alan doğrulama
- `2d58164` — 2.2 Kategori kartları ve filtreli eğitim listesi
- Çalışma `baran` dalındadır. Bu aşamada push veya PR oluşturulmadı.

## Karşılaştığım sorunlar

- Form testlerinde varsayılan başlangıç rotası ana sayfayı da oluşturuyordu;
  test rotaları bağımsızlaştırıldı. Son test çalıştırması tamamen geçti.

## Gelecek hafta

- **3.1:** HTTP API servisi, JWT ile giriş ve oturum bilgisinin saklanması.
- **3.2:** Kod editörü, Çalıştır / Test et istekleri ve görev bazlı sonuç kartları.
