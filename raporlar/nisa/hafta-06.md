# Hafta 06 — Nisa Ataizi

## Yaptıklarım
- 6.2 İçerik aracına --artimli ve --durum-dosyasi eklendi. Gerçek aktarım paketinin kararlı SHA-256 özetiyle yeni/değişmiş dersler seçiliyor, değişmemiş dersler için HTTP isteği gönderilmiyor; tam aktarım korundu.
- Hedefe özel yerel kayıt yalnız başarılı POST ve mevcut geri okuma doğrulamasından sonra yazılıyor. Kısmi hatada başarılı dersler korunuyor; başarısız/bekleyen dersler sonraki komutta yeniden deneniyor. Dry-run kaydı değiştirmiyor; kaynakta eksilen dersler silinmiyor.
- 6.4 kapsamında kendi değişikliğim için 10 odaklı test eklendi; toplam 73 Dart testi geçti. Değişen Dart dosyaları biçimlendirildi; dart analyze temiz. API istekleri mevcut sahte API altyapısıyla doğrulandı.
- Gerçek algoritma kaynağında dry-run: 4 ders, 12 görev (8 kod, 4 açıklama), 4 yüklenecek / 0 atlanacak. HTTP ve durum dosyası yazımı yok. README kullanım/sınırları güncellendi.

## Commit'ler / PR
- Henüz oluşturulmadı. Commit, push veya PR yapılmadı.

## Karşılaştığım sorunlar
- Yerel API bağlantısı kurulamadı; gerçek aktarım/entegrasyon ve kod çalıştırma denenmedi. Ortak 6.4 görevinin tamamı bu çalışma kapsamında değildir.
- API'de sürüm/hash ve ders testKodu geri okuması yok; backend/DB değiştirilmedi. Yerel kayıt sunucudaki dış düzenlemeleri/DB geri yüklemesini algılamaz; bu durumda tam aktarım veya yeni durum dosyası gerekir. Ders testKodu için sunucu POST onayı esas alınır.
- Algoritma kök kontrol programı ve ek arşiv belgeleri API kapsamı dışında; mevcut kayıp raporu/onay ve v2 geçiş korumaları korunuyor.

## Gelecek hafta
- API hazır olduğunda artımlı ilk yükleme, değişmeyeni atlama ve değişmiş dersin geri okumasını gerçek ortamda doğrulamak.
