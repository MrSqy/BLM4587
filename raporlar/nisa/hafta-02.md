# Hafta 02 — Nisa Ataizi

## Yaptıklarım
- 2.3 Ders başlığı/sırası, Markdown, görev açıklamaları ve başlangıç dosyalarından UTF-8 JSON üretimi ekledim; eski keşif ve listeleme davranışı korundu.
- Obsidian callout/wiki bağlantılarını işledim; kod blokları korunuyor, desteklenmeyen biçimler uyarılıyor. Çözümler dışa aktarılmıyor.
- Görev-test eşleştirmesi, tam test/yardımcı dosyaları ve çok dosyalı görev desteği ekledim. Gerçek kaynaktaki çıktı/girdi kontrol ölçütleri de saklanıyor.
- Dart 3.13.5 ile format kontrolü ve `dart analyze` başarılı; toplam 18 test geçti (3 eski, 15 yeni). Testler geçici dizinler kullanıyor.
- Gerçek kaynak: 20 ders, 140 görev (100 kod, 40 açıklama), 100 çıktı kontrolü; eksik beklenen çıktı yok. JSON yeniden okundu; iki üretimin SHA-256 değerleri aynı. Çıktı: `tools/egitim_icerik/build/egitimler.json` (Git dışında).

## Commit'ler / PR
- Bu hafta için henüz commit veya PR oluşturulmadı; push yapılmadı.

## Karşılaştığım sorunlar
- Kaynakta `test_gorev_N` yok: her ders ortak `kontrol/kontrol.py` kullanıyor. Test uydurulmadı; ders başına bir, toplam 20 uyarı üretildi. Eşleştirme küçük test kaynaklarıyla doğrulandı.
- Dart ilk denemede sandbox içindeki kullanıcı ayar erişimi nedeniyle çalışmadı; izinli ortamda kontroller tamamlandı. Ayrıştırma sırasında bulunan blok sınırı ve UTF-8 hata durumu testlerle düzeltildi.
- Araç yalnız okur/ayrıştırır; Python çalıştırmaz. Harici Python bağımlılıklarını kurmaz; karmaşık iç içe Markdown biçimleri için README'de sınırlamalar belirtildi.

## Gelecek hafta
- 3. hafta kapsamında JSON içeriğinin API'ye aktarımını ele almak.
