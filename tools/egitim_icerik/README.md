# egitim_icerik

Python ve Teknik Mülakatlar demo eğitimlerini okuyup UTF-8 JSON üreten bağımsız Dart aracı.
Python kodu/testleri çalıştırmaz; kaynak dosyalarını değiştirmez. Seçilmiş dersler için
API yükleme/dry-run komutu aşağıda açıklanmıştır; tam aktarımda sözleşme engelleri vardır.

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
`icerikMarkdown` (README + ALISTIRMALAR), `baslangicKodu` (varsa calisma.py), `testKodu`
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


## Web API'ye yükleme — v2 görev sözleşmesi

BLM4581 `0ff6cfc` ve BLM4587 `2a40b5e` main güncellemeleri temel alınmıştır.
Backend sözleşmesi: `docs/GOREV_AKTARIMI_V2.md`, `Contracts/IcerikPaketi.cs`,
`Services/IcerikAktarimServisi.cs`. Bu çalışma backend uygulama kodunu değiştirmez.
Mevcut listeleme ve dışa aktarım JSON'u (`semaSurumu: 1`) korunur; yükleme adaptörü
bundan ayrı **`surum: 2`** paketi oluşturur. Eski pytest içeriği için açıkça
`--surum 1` kullanılabilir; v2 dersi v1 ile güncellemek backend'de de yasaktır.

### Önce yalnız PY-01 dry-run

Paket klasöründe:

```powershell
dart run bin/egitim_icerik.dart yukle --kaynak C:\dev\python-egitim --api http://localhost:5080 --ders PY-01 --dry-run
```

Dry-run sıfır HTTP isteği gönderir, oturum açmaz, DB/çalışan API sürümünü denetlemez.
Adres açıkça verilir. Örnekteki port backend HTTP geliştirme profilidir; API'nin
gerçekten çalıştığını kanıtlamaz. `--ders` virgülle ayrılmış açık seçimdir; bütün
dersler varsayılan değildir. Python v2 geçişinin ilk gerçek denemesi yalnız PY-01 ile yapılmıştır; diğer dersler ayrıca seçilmelidir.

PY-01 çıktısı: v2, 7 görev = 5 kod + 2 açıklama. Kod görevlerinde başlangıç yolu,
UTF-8 kod, beklenen çıktı, stdin, beklenen çıkış kodu ve yasaklar aynen taşınır.
Satır sonları/boşluklar trim edilmez. Bilerek bozuk başlangıç programı çalıştırılmaz
ve düzeltilmez. Açıklama görevleri dosya/kontrol null ve boş başlangıç koduyla gider.
Geçici `id/kategoriId/egitimId` alanları POST edilmez; kalıcı ilişkileri sunucu kurar.

### Giderilen ve kalan alan farkları

| Bilgi | V2 yükleme davranışı |
|---|---|
| Görev no/başlık/açıklama | Aynen taşınır |
| Görev türü | Başlangıç dosyası varsa `kod`, yoksa doğrulanmış `aciklama` |
| Görev başlangıç yolu/kodu | Aynen taşınır; dosya gerçekten var ve içerik eşit olmalı |
| `kontrol` | Beş alanı aynen taşınır; eksik/null değer uydurulmaz |
| README + ALISTIRMALAR | Konu anlatımı ve Alıştırmalar bölümleriyle `icerikMarkdown` içinde korunur |
| LAB/TROUBLESHOOTING | Ana içeriğe aktarılmaz; ayrı ek içerik kaybı olarak raporlanır |
| `ornek.py` | Öğretici örnek, görev başlangıcı değildir; arşivlenmediği raporlanır |
| `ortakDosyalar` | Kaynak kontrol programı arşivlenmez; v2 sunucu kontrolü bunun yerine çalışır |
| Ek modül/veri/proje dosyaları | Bağımsız program sözleşmesi desteklemez; yerel hata, onayla aşılamaz |
| `test_gorev_N`/pytest | V2 stdout kontrolüne otomatik çevrilmez; v1/ayrı uyarlama gerekir |

PY-01 çalıştırma için gereken görev verileri artık eksik değildir. Ancak **tam
kaynak arşivi** hâlâ taşınmıyor. Varsayılan koruma arşiv eksiklerinde de çıkış 2
ile durur. Bu kapsam bilinçli kabul edilirse aşağıdaki komut yalnız yerel planı
onaylar, yine hiçbir HTTP isteği göndermez:

```powershell
dart run bin/egitim_icerik.dart yukle --kaynak C:\dev\python-egitim --api http://localhost:5080 --ders PY-01 --dry-run --kismi-aktarimi-onayla
```

Ek modül/veri engeli bu bayrakla kaldırılamaz. V2 yolu yalnız
`gorevler/[A-Za-z0-9_-]+.py` olabilir; her görevde tekil olmalı. DTO limitleri:
görev kodu 100000, beklenen çıktı 64000, stdin 32000 karakter, çıkış kodu 0–255,
en fazla 30 yasak (her biri 1–100 karakter). Diğer kategori/ders/görev ve 5 MiB
paket limitleri de doğrulanır. Genel JSON üreticisi daha geniş kaynakları
arşivlemeye devam eder; bu onların v2'de çalıştırılabildiği anlamına gelmez.

### Geçiş ve mevcut veriyi koruma

Baran'ın `20261105215923_GorevBazliKontrol` migration'ı yalnız görev tablosuna
`Aktif`, `Tur`, `BaslangicDosyasi`, `BaslangicKodu`, `KontrolJson` ekler. Varsayılan
eski görevler aktif ve `eski-pytest` kalır. Migration içerik aktarımı yapmaz;
uygulama açılışı da migration'ı kendiliğinden uygulamaz.

**Güncel ortamda migration geçmişi ayrıca okunmalıdır.** Backend ekibi/kullanıcı,
önce DB yedeğini alıp API'yi durdurduktan sonra mevcut kurulu EF aracıyla:

```powershell
cd C:\Users\pc_X\BLM4581
dotnet ef database update --project src/EgitimPlatformu.Web
dotnet run --project src/EgitimPlatformu.Web --launch-profile http
```

Araç kurulu değilse backend'in mevcut EF kurulum yönergelerini izleyin. Migration
zaten uygulanmışsa tekrar gerekmez. 3. haftadaki yerel yedek/migration ve PY-01 aktarım sonuçları `raporlar/nisa/hafta-03.md` içindedir. Kaynak kodun güncel olması çalışan işlemin güncel olduğunu göstermez.

V2 paketi **seçilen dersin tam görev listesidir**. Kod/kategori/no eşleşmesinde
ID'ler korunur; pakette olmayan eski görev `Aktif=false` olur, satırı silinmez.
PY-01 için görev 8 pasifleşir. 1–7'nin metni/kodu/kontrolü yenilenir: eski metinlerin
ayrı sürüm arşivi oluşturulmaz. Paket dışındaki dersler etkilenmez. Eski ders
başlangıç/test alanlarına da paketteki değerler yazılır; PY-01'de bunlar boştur.
Bu yüzden eski ders kod/test verisini korumak için DB yedeği zorunludur.

İstemci, mevcut derse boş ders kod/test alanı yazmayı varsayılan olarak hâlâ
engeller. `--kismi-aktarimi-onayla` bunu açmaz. Yalnız açık
`--v2-gecisini-onayla` + v2 paket + çalışan sunucudan doğrulanmış v2 sözleşmesi
birlikte geçişe izin verebilir. Bu bayrak DB yedeğini **otomatik almaz**; yedeğin
alındığı ve 1–7 güncellemesi/8 pasifleştirmesinin onaylandığı anlamına gelir.
V1 paketinde geçiş bayrağı reddedilir. Tekrar v2 yüklemelerinde de bu ihtiyatlı
koruma uygulanır; ID'ler değişmez, kopya üretilmez.

Gerçek yükleme öncesi yalnız GET ile OpenAPI'de paket sürümü 2, görev/kontrol
alanları ve görev test endpoint'i aranır. Eski/erişilemeyen Swagger veya DB
okuma hatası varsa hiçbir giriş/aktarım POST'u gönderilmez. Swagger şema
migration'ının kanıtı değildir; mevcut ders/kategori sorgularının da çalışması
gerekir. API'nin Swagger'ı yalnız Development ortamında açıktır; bu CLI gerçek
yazmayı yalnız loopback adreslerde destekler.

### Kimlik doğrulama ve gerçek aktarım sınırı

`POST /api/icerik/aktar` yönetici Identity **cookie + CSRF** kullanır. Araç giriş
formunu, sonra `GET /api/icerik/antiforgery` tokenını alır; token
`X-CSRF-TOKEN` başlığında gider. Sırlar yalnız `EGITIM_EPOSTA` ve `EGITIM_SIFRE`
ortam değişkenlerinden alınır, argümana/dosyaya/loga yazılmaz. Çerez/JWT bellekte
kalır. Korunan geri okumalar gerekirse `/api/hesap/giris` JWT'siyle yapılır.
TLS kontrolü kapatılmaz ve yönlendirmeler otomatik izlenmez.

**Bu komut eski PY-01 verilerini yenileyebilir; yalnız ilgili ders için açık geçiş onayıyla kullanılmalıdır.**
DB yedeği, migration/API, yönetici erişimi ve iki kapsam onayı hazır olduğunda
ayrıca gerçek aktarım kararı verilmelidir. Sonradan kullanılabilecek biçim:

```powershell
cd C:\dev\BLM4587\tools\egitim_icerik
dart run bin/egitim_icerik.dart yukle --kaynak C:\dev\python-egitim --api http://localhost:5080 --ders PY-01 --surum 2 --kismi-aktarimi-onayla --v2-gecisini-onayla
```

Tek paket transaction'dır. Yazma POST'u otomatik tekrarlanmaz; hata/kopmada
kayıt sonucu doğrulanmadıkça başarılı sayılmaz. Geri okumada sunucu kimliği,
kategori/egitimId ilişkileri, aktif görev sayısı, metinler, görev türü, başlangıç
kodu/yolu ve kontrol nesnesinin tamamı doğrulanır. Ekstra görev veya eksik kontrol
başarı sayılmaz. GET'in döndürmediği ders `testKodu` içeriği doğrulanmış sayılmaz.
HTTP 401/403/400/409/413/429/5xx ve bağlantı/TLS/zaman aşımı ayrı raporlanır;
sunucu hata gövdesi hassas bilgi taşıyabileceğinden loglanmaz.

Çıkışlar: 0 = kabul edilen yerel dry-run veya geri okumayla doğrulanan aktarım;
1 = hata/doğrulanamayan aktarım; 2 = açık kapsam onayı bekleyen arşiv/alan kaybı.
`--zaman-asimi` istek başına 1–120 saniyedir. Mock test başarısı gerçek aktarım
olarak raporlanmaz; güncel sonuç `raporlar/nisa/hafta-03.md` içindedir.

### Birleşik ana ders metni

Tek H1 ders başlığını `## Konu anlatımı` ve `## Alıştırmalar` izler.
Kaynakların ilk H1 başlıkları bölüm başlıklarına bağlanır; diğer başlıklar
bölüm altında küçültülür (H6 korunur ve uyarılır). Kod blokları ve satır içi kod
başlık/bağlantı dönüşümünden etkilenmez. Kaynak dosyalar değiştirilmez.
README/ALISTIRMALAR arasındaki Markdown bağlantıları ve başlık referansları
birleşik metnin başlık bağlantılarına dönüştürülür; yinelenen başlıklar numaralanır.
Başlık bağlantıları Markdown görüntüleyicisinin başlık kimliği desteğini gerektirir.
Diğer göreli dosya/resim bağlantıları korunur ve uyarılır; API dosya URL'si
uydurulmaz, ek dosyalar bu işlemle sunucuya yüklenmez.
V2 kayıp raporu birleşik metni yeniden hesaplayarak ana içeriği doğrular;
eski JSON içindeki gerçekten aktarılmayan README metni kayıp olarak kalır.
## 4.2 Teknik Mülakatlar demo kaynağı

Doğrulanan kaynak `C:\dev\teknik-mulakat-demo`; tam algoritmalar koleksiyonu
olarak sunulmaz. Kaynak README/NOTICE, bunun dört üniteli bir uyarlama olduğunu
belirtir. `teknik-mulakat-v2.json` varsa araç TM-DEMO biçimini otomatik seçer.
Manifest yokken TM-DEMO klasörleri bulunursa eksik kaynak hatası verir.

| Alan | Kaynak ve davranış |
|---|---|
| Kategori | Manifestten: `TM-DEMO`, `Teknik Mülakatlar`, sıra 50, özgün açıklama |
| Dersler | `TM-DEMO-00`, `TM-DEMO-01`, `TM-DEMO-14`, `TM-DEMO-27`; manifest sırası 1–4, klasör numarası sıra değildir |
| Görevler | Her derste 2 kod + 1 açıklama; toplam 12 görev, 8 stdout kontrolü |
| Başlangıç/kontrol | Gerçek `gorevler/*.py`, Markdown Dosya/Girdi/Beklenen çıktı ve JSON alanları karşılaştırılır |
| Ana metin | README + ALISTIRMALAR; konu anlatımı, ipuçları ve kod blokları korunur |
| Paket açıklaması | Markdown'da bulunmayan ek paket notu görev açıklamasına ayrı bölümle eklenir |
| Öz değerlendirme | Kaynak alıştırmadaki `details` metni korunur ve görüntüleyici desteği uyarılır; çözüm dosyası değildir |
| Çözümler | `cozumler`, `çözümler`, `solutions` ağaçları, CEVAPLAR.md ve referans.py okunmaz |
| Yerel arşiv | Kök kontrol.py `ortakDosyalar` içinde; kök README/NOTICE/LICENSE/LICENSE-CODE `ekBelgeler` içinde korunur |

Tek kaynak/çıktı modeli kullanılır. Dışa aktarım içi kategori kimliği PY=1,
TM-DEMO=2; TM-DEMO ders kimliği 1000000 + manifest sırasıdır. Bunlar DB kimliği
olarak gönderilmez. Kategori/ders kimliği veya kod/sıra/görev numarası çakışmaları
reddedilir; kategoriId ilişkisiyle gruplama kontrol edilir. PY keşfi ve sayısal
sıralaması korunur. TM-DEMO yalnız v2 yüklemeyi destekler.

Manifest ile Markdown/başlangıç dosyası veya kontrol uyuşmazlığında ders kodu
ve manifest yolu içeren hata oluşur. Eksik başlangıç/test uydurulmaz; kontrol.py,
öğrenci kodu veya pytest çalıştırılmaz. Tanımsız manifest alanları ve kök dosyaları
reddedilir. Ek ders Markdown'ı JSON'da korunur, API'ye gitmiyorsa kayıp raporuna
alınır; ek modül/veri dosyası v2 çalışma engelidir ve kısmi onayla aşılamaz.
Sembolik kaynak bağları izlenmez.

### Üretim ve dry-run

Paket klasöründe (`dart` PATH'te değilse kurulu Dart SDK yolunu kullanın):

```powershell
dart run bin/egitim_icerik.dart C:\dev\teknik-mulakat-demo
dart run bin/egitim_icerik.dart C:\dev\teknik-mulakat-demo build/teknik-mulakat.json
dart run bin/egitim_icerik.dart yukle --kaynak C:\dev\teknik-mulakat-demo --api http://localhost:5080 --ders TM-DEMO-00,TM-DEMO-01,TM-DEMO-14,TM-DEMO-27 --dry-run
```

Varsayılan dry-run çıkışı 2'dir: öğrenci ders/görev verileri v2'ye sığar fakat
API'de ortak kontrol ve ek kök belgeleri için kaynak arşivi alanı yoktur.
Kullanıcı bu dosyaların sunucu arşivine alınmamasını 16 Kasım 2026'da onayladı.
Onaylı kapsamın sıfır HTTP planını göstermek için:

```powershell
dart run bin/egitim_icerik.dart yukle --kaynak C:\dev\teknik-mulakat-demo --api http://localhost:5080 --ders TM-DEMO-00,TM-DEMO-01,TM-DEMO-14,TM-DEMO-27 --dry-run --kismi-aktarimi-onayla
```

Bu onay eski ders/görevleri değiştirme veya pasifleştirme onayı değildir.
Mevcut boş ders kod/test alanı koruması devam eder. Aynı kodla ders varsa önce
etkisi incelenip ayrıca karar alınmalıdır; `--v2-gecisini-onayla` otomatik eklenmez.
TM-DEMO kategorisinin mevcut ad/açıklama/sırası kaynakla farklıysa gerçek komut
hiçbir POST göndermeden durur. Diğer kategoriler korunur.

### Yerel ortam ve gerçek aktarım

Dry-run API bağlantısını veya DB kayıtlarını kontrol etmez. Kapalı API bağlantısı
ayrıştırma hatası değildir. Kurulu Docker Desktop çalıştıktan sonra backend kökünde:

```powershell
cd C:\Users\pc_X\BLM4581
docker compose up -d --no-build --pull never db
dotnet build src/EgitimPlatformu.Web --no-restore
dotnet run --project src/EgitimPlatformu.Web --no-build --launch-profile http
```

Migration uygulanmış varsayılmaz; eksik şema varsa önce salt okunur kontrol ve
yedekleme planı gerekir. Bu komutlar imaj/Android SDK indirmez. Kullanıcı DB'sini
sıfırlamayın. Yönetici kimlik bilgilerini mevcut `EGITIM_EPOSTA/EGITIM_SIFRE`
yöntemiyle yalnız süreç belleğinde tanımlayın; komut satırına veya dosyaya yazmayın.
Yeni ve çakışmayan dersler için onaylı aktarım biçimi:

```powershell
cd C:\dev\BLM4587\tools\egitim_icerik
dart run bin/egitim_icerik.dart yukle --kaynak C:\dev\teknik-mulakat-demo --api http://localhost:5080 --ders TM-DEMO-00,TM-DEMO-01,TM-DEMO-14,TM-DEMO-27 --kismi-aktarimi-onayla
```

Geri okuma kategori kimliği/ad/açıklama/sıra, ders metni/ilişkisi ve tüm görev
başlangıç/kontrol alanlarını karşılaştırır. Aktarım başarısı Python çalıştırma
altyapısı başarısı değildir. Gerçek sonuç ve kalan engeller `raporlar/nisa/hafta-04.md`
içindedir. Tam kaynak arşivi istenirse backend `Contracts/IcerikPaketi.cs` içinde
`ortakDosyalar/ekBelgeler` benzeri alanlar ve servis/modelde bunların kalıcı saklanması
gerekir; bu çalışmada backend veya Flutter kodu değiştirilmez.

### Haftalık video

1. Terminalde kaynak listeleme ve JSON üretimini göster: 4 ders, 12 görev, 8 kontrol.
2. `build/teknik-mulakat.json` içinde TM-DEMO kategorisini, iki ana metin bölümünü,
   bir başlangıç dosyasını ve boşluk/satır sonları korunmuş kontrolü aç.
3. Varsayılan dry-run'ın arşiv korumasını ve onaylı dry-run'ın yerel planını karşılaştır.
4. `dart analyze` / `dart test` sonucunu göster. Gerçek aktarım yapılmışsa API GET
   doğrulamasını ayrıca göster; bağlantı yoksa dry-run'ı gerçek aktarım gibi anlatma.
5. Parola, cookie, token veya bağlantı dizesi içeren terminal/dosya açma.

### 16 Kasım 2026 gerçek sonuç

Onaylanan kısmi kapsamla **TM-DEMO-00/01/14/27**, yeni TM-DEMO kategorisine
(DB kategoriId=3) aktarıldı: 4 ders, 12 aktif görev, 8 kod başlangıcı/çıktı kontrolü.
API geri okuması metin/kategori/görev/kod/kontrol eşliğini doğruladı. Mevcut üç
ders, 24 görev ve PY/TMA kategorilerinin tam içerik özetleri değişmedi.
`--v2-gecisini-onayla` kullanılmadı; eski kayıt güncelleme/pasifleştirme yapılmadı.
Doğrulanmış yedek ve teknik kontrol özetleri depo dışında saklandı.

Bu oturumda Docker ve API başlatıldı; eksik JWT anahtarı dosyaya yazılmadan yalnız
API sürecinin ortamında üretildi. API yeniden başlatılırsa korunan geri okumalar
ve mobil giriş için geçerli `Jwt:Anahtar` yapılandırması gerekir. Yerel geliştirmede
API'yi başlatacağın PowerShell sürecinde değerini yazdırmadan üretme biçimi:

```powershell
$env:Jwt__Anahtar = [Convert]::ToBase64String([Security.Cryptography.RandomNumberGenerator]::GetBytes(48))
dotnet run --project src/EgitimPlatformu.Web --no-build --launch-profile http
```

Her yeni anahtar eski JWT'leri geçersiz kılar; anahtarları paylaşma veya loglama.
Parolası saklanmayan yerel aktarım yöneticisi proje başlangıç yöntemiyle hazırlandı;
kişisel hesabın parolası değiştirilmedi. Sonraki yönetim oturumları için kendi
kimlik bilgilerini güvenli yerel girişle tanımlamalısın.

Kontroller: `dart format`, temiz `dart analyze`, **63 Dart testi** (18 yeni), gerçek
Python regresyon üretimi 20 ders/140 görev/100 kontrol; demo JSON'u yeniden
okundu ve tekrar üretimde SHA-256 eşitliği doğrulandı. **Python kodu veya sandbox
çalıştırılmadı.** Videoda yalnız aktarım/geri okuma başarısı olarak sun.
İlk yeni dersin misafire açık geri okuması:

```powershell
Invoke-RestMethod http://localhost:5080/api/mobil/kategoriler
Invoke-RestMethod http://localhost:5080/api/mobil/egitimler/4
```

Diğer demo dersleri 5, 6, 7 kimliklerini aldı; detayları Bearer girişi gerektirir.
Tekrar gerçek yükleme mevcut kayıt değişikliğidir: otomatik çalıştırmayın, dry-run
ve etki incelemesini yenileyin.