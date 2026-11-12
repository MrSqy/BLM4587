# Hafta 04 — Baran Demir

**Ders:** BLM4587 · **Tarih:** 9–15 Kasım 2026 · **Lider:** Nisa

## Yaptıklarım

- **4.1 Gönderim geçmişi:** İlerleme sekmesini yer tutucudan kişisel gönderim listesine dönüştürdüm. Misafir kullanıcıya giriş seçeneği gösteriliyor. Oturum sahibi ders, görev, sonuç ve yerel saatte gönderim tarihini görüyor. Gönderim sayısı sunucunun döndürdüğü toplamdan geliyor.
- Liste 20 kayıtlık sayfalarla yükleniyor. Sekmeye dönünce veya aşağı çekerek yenileyince ilk sayfa tekrar alınıyor. Daha fazla kayıt gösterilirken mevcut kimlikler korunuyor ve tekrarlar ayıklanıyor. Yüklenme, boş geçmiş ve servis hatası ayrı gösteriliyor. Hata durumunda kullanıcı yeniden deneyebiliyor.
- Gönderim ayrıntısı gerçek kayıt kimliğiyle açılıyor. `FutureBuilder` ayrıntının yüklenme ve hata durumlarını gösteriyor. Ayrıntıda gönderilen kod, standart çıktı, hata, çıkış kodu ve çalışma süresi okunabiliyor. Boşluk ve satır sonları korunuyor. Görev alanı boş olan eski ders kayıtları da okunabiliyor.
- Oturum değişince liste temizleniyor. Önceki oturumun geç gelen liste yanıtı ekrana yazılmıyor. Ayrıntı ekranı da açıldığı hesap ya da oturum değiştiğinde kaydı gizliyor.
- Başarılı veya başarısız bir test yanıtı `gonderimId` içeriyorsa ders ekranı sonucun geçmişe kaydedildiğini gösteriyor. İlerleme sekmesine dönünce yeni kayıt yükleniyor.

## 4.1 ile birlikte düzeltilen sorunlar

- **Oturum dolunca taslak kaybı:** Taslakları açık ders ekranında kullanıcı, ders ve görev kimliğiyle ayırdım. Oturum dolduğunda seçili görev ve yazılan kod korunuyor. Misafire açık derste editör taslakla yeniden açılıyor. Korumalı derste aynı hesap yeniden giriş yaptığında taslak geri geliyor. Başka hesapla giriş yapıldığında o hesabın kendi taslakları kullanılıyor.
- **İstek süreleri:** Çalıştır ve Test et için ayrı, varsayılan 60 saniyelik süre tanımladım. Bu süre .NET 4.4 için planlanan 15 saniye kuyruk, 30 saniye işlem ve 15 saniye yanıt payını kapsıyor. Genel istekler 20 saniye kullanıyor. Kod işlemlerinin süresi `KOD_ZAMAN_ASIMI_SANIYE` derleme ayarıyla değiştirilebiliyor.
- **Geçmiş uçlarına erişim:** Liste ve ayrıntı `/api/gonderimler` ve `/api/gonderimler/{id}` üzerinden, aynı sunucuya Bearer başlığıyla gidiyor. İstemci mobil uçlar için adres kontrolünü koruyor. `503 kuyruk_dolu` yanıtındaki geçerli `Retry-After` süresi kullanıcıya gösteriliyor.

## Doğrulama

- Gönderim istemcisini Flutter motorunda taklit HTTP yanıtlarıyla yeniden çalıştırdım. Aynı sunucuya Bearer gönderimi, liste adresi, sayfalama, ayrıntı, boş görev alanları, çıktıdaki boşluklar, kod isteği için ayrı süre ve kuyruk dolu yanıtı geçti.
- Oturum dolması sonrasında açık ve korumalı ders taslağını, geçmişte ikinci sayfayı, hesap değişiminde eski yanıtın elenmesini ve 503 hata ekranını kapsayan widget testleri eklendi.
- Tam Flutter test paketi ve analiz bu teslim için doğrulanamadı. Yerel SDK ve paket önbelleğiyle yapılan denemede Flutter aracının `analyzer 10.1.0` bağımlılığı ve analiz için gereken bazı uygulama paketleri çözülemedi. Yukarıdaki Flutter motoru kontrolü yalnızca ilgili servis akışını kapsıyor.
- Yerel `main` ve 4.1 dalının Git birleştirme denemesi temiz geçti. Gerçek backend ile mobil uçtan uca kontrol ve bu haftanın APK/cihaz kabulü bekliyor.

## Commit ve PR kapsamı

- `1c307ac` — 4.1 gönderim geçmişi, taslak koruma ve kod isteği süresi.
- PR kapsamı Flutter 4.1, bu düzeltmeler ve Baran'ın 3. ve 4. hafta raporları.

## Gösterim için açık işler

Canlı geçmiş kontrolü için BLM4581 4.1 API'si ve `GonderimGecmisi` migration'ı uygulanmış bir test veritabanı gerekiyor. Oturumlu kullanıcıyla önce Test et çalıştırılıp ardından geçmişten aynı kayıt açılmalı. Bu sürüm gönderim geçmişini gösteriyor. Ders tamamlama yüzdesi için ilerleme API'si gerekiyor. Ortak gösterim senaryosu ve yeni test APK'sı ayrı kabul adımları.
