# Hafta 01 — Baran Demir

**Ders:** BLM4587 · **Tarih:** 19–25 Ekim 2026 · **Lider:** Ramazan

## Özet

Bu hafta depo altyapısını kurdum, 1.1 (uygulama iskeleti) ve 1.2 (modeller ve sahte veri servisi)
işlerini tamamladım. Uygulama açılınca alt menülü dört sekme ve ana sayfada ders özeti görünüyor.

## Kurulum ve depo düzeni

- GitHub deposu (public), Ramazan ve Nisa collaborator olarak eklendi.
- Flutter Android projesi (`egitim_platformu`) ve Nisa'nın içerik aracı için ayrı Dart paketi
  (`tools/egitim_icerik`).
- Herkese ayrı dal açıldı: `baran`, `nisa`, `ramazan`. `main` korumalı, yalnızca pull request ile
  değişiyor ve birleştirme yöntemi merge commit.
- `raporlar/` klasörü ve rapor şablonu eklendi; README'ye kurulum ve çalışma düzeni yazıldı.

## 1.1 Uygulama iskeleti

- Alt menü (NavigationBar): Ana sayfa, Eğitimler, İlerleme, Profil.
- Sekmeler arasında geçerken ekranların durumu korunuyor (IndexedStack).
- İsimli rotalar: `/` ana iskelet, `/hakkinda` Hakkında sayfası (Profil sekmesinden açılıyor).
- Material 3 açık ve koyu tema; telefonun tema ayarını izliyor.
- Eğitimler ve İlerleme sekmeleri, sonraki haftalarda dolacak yer tutucular.

## 1.2 Modeller ve sahte veri servisi

- `Kategori`, `Egitim`, `Gorev` sınıfları; JSON'dan okuma ve JSON'a yazma (fromJson/toJson).
  Alanlar BLM4581 Web API'siyle aynı.
- `EgitimServisi` arayüzü: kategorileri, dersleri ve tek bir dersi getirir.
- `SahteEgitimServisi`, API ile aynı biçimdeki `assets/sahte_veri.json` dosyasını okuyor
  (PY-01..PY-03 dersleri, 24 görev). API hazır olunca aynı arayüzle gerçek servis yazılacak.
- Ana sayfa bu servisten kategori, ders ve görev sayılarını gösteriyor.

## Durum

- `flutter analyze`: sorun yok. `flutter test`: 9 test geçti.
- Telefonda henüz denenmedi (Android lisansları kabul edilecek).
- Değişiklikler `baran` dalında; `main`'e birleştirme için PR açık:
  https://github.com/MrSqy/BLM4587/pull/1

## Gelecek hafta

- 2.1 Giriş ve kayıt ekranları, form doğrulama
- 2.2 Eğitim listesi ve kategori kartları
