# Hafta 03 — Nisa Ataizi

## Yaptıklarım
- 3.3 Seçili ders yükleme, sıfır HTTP dry-run, yönetici cookie/CSRF ve API geri okuma doğrulaması eklendi; Baran'ın v2 görev sözleşmesine uyum sağlandı.
- README konu anlatımı ve ALISTIRMALAR ana ders metninde birleştirildi; başlık/bağlantı dönüşümü ve kayıp raporu düzeltildi. Son Dart kontrolünde format/analiz temiz, 45 test başarılı.
- Yerel DB yedeği ayrı veritabanına geri yüklendi; tablo içerikleri doğrulandı. İki bekleyen migration uygulandı, güncel API yeniden başlatıldı; eski içeriklerin korunduğu kontrol edildi.
- Desteklenen başlangıç komutuyla yerel yönetici hazırlandı; parola yalnız bellekte kullanıldı. Kullanıcının açık onayıyla yalnız PY-01 için v2 kısmi aktarım denemesi başarıyla tamamlandı (2026-11-06).
- API GET ile birleşik ana metin, 7 aktif görev, 5 başlangıç kodu/çıktı kontrolü ve ders ilişkileri kaynakla birebir doğrulandı. Eski 8. görev API'de listelenmiyor; salt okunur DB kontrolü aynı kimlik/içerikle silinmeden pasif kaldığını doğruladı. Diğer dersler ve kategoriler değişmedi.

## Commit'ler / PR
- Yeni commit, push veya PR oluşturulmadı.

## Karşılaştığım sorunlar
- Onaylanan kısmi kapsamda ornek.py, LAB/TROUBLESHOOTING ve ortak kontrol programı arşivlenmedi; ek dosyalara göreli bağlantılar korunup uyarıldı. README/ALISTIRMALAR ana metinde korunuyor.
- Ders düzeyindeki eski kod/test alanları açık onayla boşaltılıp görev bazlı yapıya geçildi; önceki değerler doğrulanmış yedekte duruyor. Pasif görev bilgisi mevcut API'den doğrudan okunamıyor; DB ile doğrulandı.
- Python kod çalıştırma ve öğrenci test altyapısı denenmedi. Aktarım/geri okuma başarısı kod çalıştırma başarısı değildir; tüm derslerin eksiksiz aktarımı tamamlanmış sayılmıyor.

## Gelecek hafta
- Kod çalıştırma/test altyapısını ayrıca doğrulamak; ek eğitim materyalleri ve göreli bağlantılar için sunum/arşiv kararını netleştirmek.
- Diğer derslerin veri/modül bağımlılıklarını ayrı incelemek; yeni onay olmadan yüklememek.
