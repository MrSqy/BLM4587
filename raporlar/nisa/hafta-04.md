# Hafta 04 — Nisa Ataizi

## Yaptıklarım
- 4.2 Ön incelemede kaynak bulunamamış, araç/backend incelenip 45 mevcut test doğrulanmıştı. 16 Kasım'da nisa/origin-main 40a90c4 üzerinde, eklenen teknik-mulakat-demo kaynağıyla devam edildi; önceki çalışma korundu.
- Manifest, Markdown ve gerçek başlangıç/kontrol çapraz doğrulaması; TM-DEMO kategorisi/sıralaması, birleşik konu-alıştırma metni, çözüm dışlama ve kimlik/kategori çakışması korumaları eklendi. README komutları güncellendi.
- Dry-run: 4 ders, 12 görev (8 kod + 4 açıklama), 8 kontrol. DB yedeği ayrı DB'ye geri yüklenerek doğrulandı. Kullanıcının arşiv eksikleri için açık onayıyla yerel kısmi gerçek aktarım tamamlandı; API GET bütün ders metinlerini, ilişkileri ve başlangıç/kontrolleri kaynakla eşleştirdi.
- Eski 3 ders/24 görev ve PY/TMA kategorileri tam içerik özetleriyle değişmeden doğrulandı. Format/analiz temiz, 63 Dart testi başarılı; gerçek Python üretimi 20 ders/140 görev/100 kontrol olarak korundu.

## Commit'ler / PR
- Henüz oluşturulmadı. Commit, push veya PR yapılmadı.

## Karşılaştığım sorunlar
- Başta Docker/API kapalıydı; kurulu ortam indirme yapılmadan başlatıldı. Migration geçmişi salt okunur kontrol edildi; migration uygulanmadı. Yerel yönetici ve JWT sırları yalnız bellekte kullanıldı.
- Kontrol.py ve kök README/NOTICE/LICENSE/LICENSE-CODE API'de arşivlenmiyor; onaylanan bu eksikler yerel JSON'da korunuyor. V2 bağımsız Python/stdout ile sınırlı; ek modül/veri görevleri engelleniyor. HTML öz değerlendirme blokları korunuyor, gösterimi görüntüleyiciye bağlı.
- Python/öğrenci kod çalıştırma ve gerçek sandbox test altyapısı denenmedi; aktarım doğrulaması bu altyapının başarı kanıtı değildir. Kaynak, Flutter/backend kodu ve docker-compose değişikliği korundu.

## Gelecek hafta
- Gerçek kod çalıştırma/test altyapısını ayrıca doğrulamak; ek kaynak arşivi ve çok dosyalı dersler için gereken sözleşmeyi ekip ile netleştirmek.
- Yeni aktarım veya mevcut görevleri değiştirme/pasifleştirme öncesi etkileri yeniden incelemek; mevcut kapsam onayını bunun için kullanmamak.
