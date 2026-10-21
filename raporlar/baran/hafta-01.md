# Hafta 01 — Baran Demir

## Yaptıklarım
- 1.1 Uygulama iskeleti: NavigationBar ile dört sekme (Ana sayfa, Eğitimler, İlerleme, Profil),
  IndexedStack, isimli rotalar (`/`, `/hakkinda`), Material 3 açık/koyu tema.
- 1.2 Kategori, Egitim, Gorev model sınıfları (fromJson/toJson) ve `EgitimServisi` arayüzü.
  `SahteEgitimServisi`, API ile aynı biçimdeki `assets/sahte_veri.json` dosyasını okuyor.
  Ana sayfa bu servisten kategori, ders ve görev özetini gösteriyor.
- Model, servis ve widget testleri (9 test).

## Commit'ler / PR
- PR: https://github.com/MrSqy/BLM4587/pull/1

## Karşılaştığım sorunlar
- Widget testlerinde asset dosyası okuması sahte saatte bitmediği için `pumpAndSettle` zaman aşımına
  uğradı. Veriyi `setUpAll` içinde testlerden önce bir kez yükleyerek çözdüm.

## Gelecek hafta
- 2.1 Giriş ve kayıt ekranları; Form ve TextFormField ile doğrulama
- 2.2 Eğitim listesi (ListView.builder, kategori filtresi), kategori kartları (GridView)
