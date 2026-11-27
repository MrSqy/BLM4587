# TM-DEMO-00 — Mülakata başla: girdiyi ve çıktıyı oku

## Konu anlatımı

Bir mülakat sorusunu duyduğunda hemen kod yazma. Önce **ne verildiğini**, **ne döndüreceğini** ve **boş girdide ne olacağını** söyle. Sonra küçük bir örneği elle çöz.

Mesela bir günlükte dolu satırları sayacaksın. Üç satır var: `hazır`, yalnız boşluk ve `bitti`. Ortadaki satırı atla; cevap `2`. Python'da `satir.strip()` baştaki ve sondaki boşlukları temizler. Sonuç boşsa o satırı sayma.

[Alıştırmalara geç](#al%C4%B1%C5%9Ft%C4%B1rmalar).

## Alıştırmalar

Önce örneği incele, sonra başlangıç dosyasında `TODO` bölümünü tamamla. Üçüncü görevde cevabını bir iki cümleyle yaz.

### Görev 1 — Dolu satırları say

**Dosya:** `gorevler/dolu_satir.py`

İlk satırdaki `n` sayısını oku. Sonraki `n` satırda boş veya yalnızca boşluk içeren satırları sayma. Dolu satırların sayısını tek satırda yaz. `n = 0` ise `0` yaz.

**İpucu:** `input()` bir satır okur. `if satir.strip():` ile dolu olup olmadığını kontrol edebilirsin.

**Girdi:**

```text
5
basla
   
kontrol

bitir
```

**Beklenen çıktı:**

```text
3
```

