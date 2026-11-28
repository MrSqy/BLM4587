# PY-01 — İlk Python programı

## Konu anlatımı

> **info: Bu ders için ön bilgi**
> - Ön bilgi gerekmez. Bu ders, daha önce hiç program yazmamış birine göre hazırlandı; gereken terminal komutları da burada anlatılıyor.
> - Terminali daha iyi tanımak istersen: [Linux 02 — Terminal ve Zsh](../../../../../sistemler-ve-ag/linux/dersler/02-terminal-zsh/README.md) (isteğe bağlı).

[Laboratuvar](LAB.md) · [Hata teşhisi](TROUBLESHOOTING.md) · [Görevler](#al%C4%B1%C5%9Ft%C4%B1rmalar)

## Alıştırmalar

Yedi görev var. Beşinde kod yazarsın (1–5), ikisinde kısa bir açıklama hazırlarsın (6, 7). Başlamadan önce [anlatımı](#konu-anlat%C4%B1m%C4%B1) ve [laboratuvarı](LAB.md) bitir.

### Kod görevleri nasıl yapılır?

Kod görevlerinin dosyaları [gorevler/](gorevler/) klasöründe. Her dosya küçük bir programdır. Kodunu `# TODO` notunun yerine yaz. `ornek.py`'ye dokunma.

Bir görevi denemek için terminal `PY-01` klasöründeyken çalıştır (README 10. bölüm):

```bash
python3 gorevler/selam.py
```

Bütün kod görevlerini birlikte kontrol ettirmek için:

```bash
python3 ../../kontrol/kontrol.py --ders PY-01
```

Test programı her görev dosyasını çalıştırır ve ekrana yazılanı aşağıdaki **Beklenen çıktı** ile harfi harfine karşılaştırır. Her görev için `GEÇTİ` ya da `KALDI` yazar. Kalan görevde beklenen çıktıyı ve programının çıktısını alt alta gösterir; Python hata verdiyse onun mesajını da gösterir. Tek bir görevi kontrol etmek için sonuna `--gorev selam` ekle.

Dosyalara henüz dokunmadıysan bütün görevler `KALDI` verir; başlangıç durumu budur.

Açıklama görevlerini kendi notuna yaz, sonra [çözüm notlarıyla](cozumler/CEVAPLAR.md) karşılaştır. Test programı bunları sınamaz.

### Görev 1 — Selam

**Dosya:** `gorevler/selam.py`

Ekrana `Merhaba, dünya!` yaz.

**Beklenen çıktı:**

```text
Merhaba, dünya!
```

