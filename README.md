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

## İçerik aracı

`tools/egitim_icerik` ayrı bir Dart paketidir. Ayrıntılar için kendi README dosyasına bakın.

## Klasör yapısı

```
lib/                     Uygulama kodu
test/                    Widget ve birim testleri
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
