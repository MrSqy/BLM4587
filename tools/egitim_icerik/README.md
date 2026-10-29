# egitim_icerik

Python eğitim deposunu okuyup UTF-8 JSON üreten bağımsız Dart aracı.
Python kodu/testleri çalıştırmaz; kaynak dosyalarını değiştirmez. API'ye yükleme yoktur.

## Çalıştırma

Dart SDK gereksinimi `pubspec.yaml` içindedir. Paket klasöründe:

```powershell
cd C:\dev\BLM4587\tools\egitim_icerik
dart pub get
dart run bin/egitim_icerik.dart C:\dev\python-egitim build/egitimler.json
```

İki konumsal argüman: kaynak depo, çıktı JSON dosyası. Çıktının üst klasörleri
oluşturulur; mevcut çıktı dosyası yenilenir. Kaynağın içine çıktı yazılması,
sembolik bağlantı üzerinden yönlendirilse de reddedilir. `build/` Git dışında tutulur.
`--help` / `-h` yardım gösterir. Eski tek argümanlı kullanım ders yollarını ve
sayısını listeler. Hatalarda çıkış kodu 1, başarıda (uyarılar dahil) 0 döner.
Uyarılar stderr'e ve JSON'daki `uyarilar` listesine yazılır.

## Kaynak düzeni

- `dersler` dizininin doğrudan altındaki `PY-<sayı>` klasörleri sayısal sıralanır.
  Eşit sayılarda yol sırası kullanılır; JSON'da yinelenen ders kimliği reddedilir.
- Ders başlığı `README.md` H1 başlığından, ders kodu ve sırası klasör adından alınır.
  `README.md` ve `ALISTIRMALAR.md` zorunludur. Görevler kod blokları dışındaki
  `## Görev N — Başlık` veya `### Görev N — Başlık` bölümlerinden çıkarılır.
- `**Dosya:**` satırı görevin başlangıç dosyasını belirler. `gorevler/` dışına
  çıkan yollar reddedilir. Eksik başlangıç dosyası uyarılır; kod uydurulmaz.
- Gerçek kaynakta her derste 5 program ve 2 açıklama görevi vardır.
  `test_gorev_N` bulunmaz: `kontrol/kontrol.py`, görev metnindeki **Beklenen çıktı**,
  **Girdi**, **Beklenen çıkış kodu**, **Kullanılmamalı** alanlarını kullanır.
  Bu bilgiler görev bazında saklanır. Girdi ve çıktı bloklarının son satır sonu
  korunur. Belirtilmeyen girdi `''`, çıkış kodu `0` olur; bu ortak kontrolün
  varsayılanıdır. Eksik/bozuk beklenen çıktı uyarılır, `null` kalır.
- Başka bir kaynakta `test_gorev_N` / `test_gorev_N_aciklama` tanımları varsa,
  Python dizgi ve yorumları maskelendikten sonra görev numarasıyla eşleştirilir.
  Dosya yolu, fonksiyon adı ve 1 tabanlı satır numarası kaydedilir. Async ve
  girintili tanımlar desteklenir. Eşleşmeyen testler ve testli derste testsiz
  kod görevleri uyarılır. Bu bir Python AST/sözdizimi doğrulayıcısı değildir.
- Test fonksiyonları tek başına kesilmez: tam dosyalar, importlar, fixture'lar,
  yardımcı modüller, `gorevler/` paketleri, proje yapılandırmaları ve veri dosyaları
  göreli yollarıyla saklanır. Dosyalar çalıştırılabilir bir paket olarak kurulmaz;
  harici Python paketleri veya depo dışı importlar çözülmez/indirilmez.
- `cozumler/` ağacı hiçbir derinlikte okunmaz. Çözümlere mevcut Markdown
  bağlantıları korunur, cevap dosyalarının içeriği dışa aktarılmaz.
  Sembolik bağlar, `.git`, `__pycache__`, `.venv`, `venv`, `build`, `dist` atlanır.

## Markdown ve Obsidian

İncelenen 20 dersin README'lerinde `> [!info]` callout'ları bulunur.
Bunlar `> **info: Başlık**` biçiminde standart Markdown alıntısına dönüşür;
katlanma işareti kaldırılır, içerik korunur. `[[Not|Etiket]]` bağlantıları
`[Etiket](<Not.md>)` olur; başlık parçaları korunur. Göreli yollar yeniden
konumlandırılmaz; Markdown dosyasının özgün dizini temel alınmalıdır.

`![[gömme]]`, blok referansları (`#^`), çok parçalı alias, `%%yorum%%` ve
`==vurgu==` korunup uyarılır. Gömme içerikleri açılmaz. Normal Markdown,
backtick/tilde kod çitleri (uzun çitler dahil), girintili ve satır içi kod
korunur. Kapatılmamış çit uyarılır. Genel bir CommonMark/Obsidian motoru değildir;
karmaşık iç içe liste/alıntı kod blokları ve çok satırlı inline kod destek kapsamı
sınırlıdır. Kaynakta görülen düz callout biçimi esas alınmıştır.

## JSON şeması (semaSurumu: 1)

Mevcut `lib/modeller` ve `assets/sahte_veri.json` alanları korunur;
çok dosyalı kaynak için ek alanlar kullanılır. Mevcut uygulama ek alanları okumaz.

| Alan | İçerik |
|---|---|
| `kategoriler` | Python kategorisi, id 1; `id`, `ad`, `kisaltma`, `sira` |
| `egitimler` | Sayısal sıralı dersler |
| `ortakDosyalar` | `kontrol/kontrol.py` tam metni (varsa) |
| `uyarilar` | Ders kodu, kaynak dosya yolu ve mesaj; kararlı sırada tekilleştirilir |

Her ders: `id` (klasördeki sayı), `kategoriId`, `kod`, `sira`, `baslik`,
`icerikMarkdown` (ALISTIRMALAR), `baslangicKodu` (varsa calisma.py), `testKodu`
(varsa test_alistirmalar.py), `gorevler`, `markdownDosyalari`, `kaynakDosyalari`,
`testler`. Olmayan tek dosyalı kod alanları boş metindir; farklı programlar
birleştirilerek yapay bir Python dosyası oluşturulmaz.

`markdownDosyalari`: README, ALISTIRMALAR ve varsa LAB/TROUBLESHOOTING dönüşmüş
metinleri. `kaynakDosyalari`: Markdown dışı dosyalar için
`"gorevler/ilk.py": {"kodlama": "utf-8", "icerik": "..."}` eşlemesi.
UTF-8 olmayan dosyalar kayıpsız `base64` kodlamasıyla saklanır.

Her görev: mevcut `id`, `egitimId`, `no`, `baslik`, `aciklama` alanlarına ek olarak
`baslangicDosyasi` (yoksa null), `baslangicKodu`, `testler` ve `kontrol` içerir.
Görev id'leri sıralı ders/görev dolaşımında 1'den atanır; kalıcı veritabanı
kimliği sayılmamalıdır. Görevler kaynak metindeki sırayı korur.

`testler`: `{ad, no, satir, dosya}` kayıtları; `dosya`, dersin
`kaynakDosyalari` alanındaki tam test modülüne işaret eder.
`kontrol`: kod görevi için `{tur: "standart-cikti", beklenenCikti,
girdi, beklenenCikisKodu, kullanilmamali}`; dosyasız açıklama görevi için null.
Kaynakta `test_gorev_N` yoksa liste boş kalır ve ders başına uyarı verilir.

## Doğrulama

```powershell
dart format --output=none --set-exit-if-changed lib bin test
dart analyze
dart test
```

Testler geçici dizinlerle çalışır; kişisel mutlak yollara bağımlı değildir.
Keşif/sıralama, Markdown/kod koruma, görev ve test eşleştirmesi, tam test
bağımlılıkları, UTF-8 JSON turu, kararlı üretim, çözüm dışlama ve hata
senaryoları denetlenir. Gerçek 20 ders üretiminin sonuçları Nisa'nın
`raporlar/nisa/hafta-02.md` raporundadır.
