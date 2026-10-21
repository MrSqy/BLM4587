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
