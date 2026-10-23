# egitim_icerik

Eğitim içeriklerini işlemek için geliştirilen Dart komut satırı aracı.

## Mevcut özellikler

- Verilen eğitim klasöründeki `dersler` dizinini tarar.
- `PY-` ve ardından sayı biçiminde adlandırılmış ders klasörlerini bulur.
- Dersleri numaralarına göre sıralayarak yollarını ve toplam sayısını gösterir.
- `dersler` dizini bulunamazsa hata mesajı verir.

## Çalıştırma

Önce bu paketin klasörüne geçip bağımlılıkları yükleyin:

```powershell
cd C:\dev\BLM4587\tools\egitim_icerik
dart pub get
```

Eğitim klasörünün yolunu argüman olarak verin:

```powershell
dart run bin/egitim_icerik.dart C:\dev\python-egitim
```

Eğitim klasörünün altında `dersler/PY-01`, `dersler/PY-02` gibi
ders klasörleri bulunmalıdır. Yol boşluk içeriyorsa tırnak içine alın.

## Kontroller

```powershell
dart analyze
dart test
```

## Planlanan özellikler

Markdown içeriklerinin, alıştırmaların ve testlerin işlenerek JSON'a
dönüştürülmesi ve Web API'ye aktarılması sonraki aşamalarda eklenecektir.