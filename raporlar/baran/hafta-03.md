# Hafta 03 — Baran Demir

**Ders:** BLM4587 · **Tarih:** 2–8 Kasım 2026 · **Lider:** Ramazan

## Yaptıklarım

- **3.1 API bağlantısı ve oturum:** Flutter'ı HTTP üzerinden BLM4581'e bağladım. Giriş ve kayıt formları birlikte doğrulanıyor, başarılı kayıt oturum açıyor. JWT ve kullanıcı bilgisi güvenli depoda tutuluyor. SharedPreferences yalnızca hassas olmayan oturum tercihini saklıyor. 15 dakikalık oturumun süresi dolduğunda veya geçerli isteğe 401 geldiğinde oturum temizleniyor. Eski bir isteğin 401 yanıtı daha yeni bir oturumu temizlemiyor. 403, 409, 429 ve 503 yanıtları oturumu koruyor.
- Misafir erişimi için sunucunun `misafireAcik` ve `erisilebilir` alanlarını kullandım. İlk ders misafire açılıyor. Kilitli dersin özeti ve giriş seçeneği gösteriliyor. Oturum kapanınca korumalı dersin içeriği ekrandan kaldırılıyor.
- Sunucu adresi `API_ADRESI` ile ayarlanıyor. Android emülatörünün varsayılan adresi `10.0.2.2:5080`. Yayın derlemesi HTTPS gerektiriyor. API hataları için `{mesaj}`, ProblemDetails ve boş HTTP yanıtları işleniyor. PR #6'ya eklenen düzeltmeyle ders yükleme hatasında sunucunun verdiği açıklama gösteriliyor.
- **3.2 Kod editörü ve sonuçlar:** Ders Markdown içeriği, Python editörü, dört boşluk girinti düğmesi, Çalıştır ve Test et işlemleri eklendi. Açık ve koyu tema, Eğitimler, Profil ve oturum ekranlarıyla uyumlu. Ana sayfadaki kategori seçimi Eğitimler sekmesindeki filtreyi açıyor.

## Görev bazlı v2 uyarlaması

İlk editör sürümü, backend'in örnek verisindeki ders başına tek Python dosyasına dayanıyordu. Güncel eğitim kaynağında her kod görevinin ayrı dosyası, girdisi ve beklenen çıktısı bulunuyor. .NET tarafındaki v2 sözleşmesi hazırlandıktan sonra mobil akışı görev bazına taşıdım.

- Her kod görevi kendi başlangıç dosyası ve koduyla açılıyor. Açık ders ekranında taslaklar ders ve görev kimliğine göre ayrılıyor. Kullanıcı bütün kodu silmişse boş taslak da korunuyor.
- Çalıştır ve Test et, `/api/mobil/egitimler/{id}/gorevler/{no}/calistir` ve `/test` uçlarını çağırıyor. Adreste görev sıra numarası, taslakta kalıcı görev kimliği kullanılıyor. İstek gövdesi yalnızca öğrencinin kodunu içeriyor.
- Açıklama görevleri Markdown ve kabul ölçütlerini gösteriyor. Eski pytest veya kontrol bilgisi eksik görevlerde güncel içerik gerektiğini belirten mesaj çıkıyor.
- Sonuç ekranı beklenen çıktı, program çıktısı, hata ve çıkış kodunu ayrı gösteriyor. Boşluklar ve satır sonları korunuyor. Çıktı uyuşmazlığı, kural ihlali, zaman aşımı, çıktı sınırı ve değerlendirilemeyen kontroller ayrı görünüyor. Çalıştırma sonucu ile otomatik test sonucu ayrı etiketleniyor.

## Doğrulama

| Kapsam | Sonuç |
| --- | --- |
| İlk 3.1 ve 3.2 teslimi | 64 Flutter testi geçti. Analiz temizdi ve debug bundle derlendi. |
| Ders yükleme hatası | İlgili 9 test ve analiz geçti. PR #6 birleşiminden sonra tam paket 64 testle yeniden geçti. |
| Görev bazlı v2 | 71 Flutter testi, analiz ve debug bundle başarılı. Taslak geçişi, istek adresi, açıklama görevi, boşlukların korunması ve hata durumları kapsandı. |
| Android emülatörü | İlk teslimin debug APK'sı açıldı. Gerçek API'den 2 kategori, 3 ders ve 24 görev yüklendi. Misafire açık ilk dersin içeriği okundu. |

İlk çevrimdışı APK denemesi eksik Gradle bağımlılığında durmuştu. Daha sonra üretilen debug APK emülatörde çalıştırıldı. Yukarıdaki emülatör kontrolü v2 öncesi derlemeye ait. V2 için cihaz üzerinde canlı Çalıştır ve Test et kabulü bekliyor. Widget ve servis testlerinde HTTP yanıtları ve güvenli depolama taklit edildi.

Nisa, kendi 3.3 çalışmasında güncel PY-01'i yükleyip API'den 5 kod ve 2 açıklama görevini geri okudu. Bu doğrulama içerik aktarımına ait. Ayrıntılar Nisa’nın `main` dalındaki `raporlar/nisa/hafta-03.md` raporunda.

## Commit’ler ve PR’lar

- `0ce3287` — Mobil oturum, ders erişimi ve kod editörü.
- `feeab9f` — Ders yükleme hatasında API açıklaması.
- **PR #6**, `145e122` ile `main`e birleşti.
- `7b228f0` — Görev bazlı v2 akışı ve çıktı karşılaştırması.
- **PR #7**, `2a40b5e` ile `main`e birleşti.

## 4. haftaya devreden konu

Görevler arası taslak koruması 3. haftada eklendi. Oturum süresi dolduğunda editörde yazılan kodun silinmesi sonraki incelemede ortaya çıktı. Düzeltme ve 4.1 gönderim geçmişi [4. hafta raporunda](hafta-04.md).
