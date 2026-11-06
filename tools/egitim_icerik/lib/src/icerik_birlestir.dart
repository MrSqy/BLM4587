import 'markdown.dart';

/// İki kaynak aynı ders klasöründedir. API için dosya URL'si uydurulmaz.
String dersMetniniBirlestir({
  required String kod,
  required String baslik,
  required Map<String, String> markdown,
  required void Function(String dosya, String mesaj) uyar,
}) {
  final kullanilan = <String, int>{};
  String benzersiz(String metin) {
    final temel = _slug(metin);
    final sayi = kullanilan.update(temel, (n) => n + 1, ifAbsent: () => 0);
    return sayi == 0 ? temel : '$temel-$sayi';
  }

  benzersiz('$kod — $baslik');
  final bolumler = <_Bolum>[];
  for (final kayit in const {
    'README.md': 'Konu anlatımı',
    'ALISTIRMALAR.md': 'Alıştırmalar',
  }.entries) {
    final ham = markdown[kayit.key];
    if (ham == null || ham.trim().isEmpty) {
      throw FormatException(
        '$kod | ${kayit.key} | Birleşik içerik için boş olmayan kaynak gerekiyor.',
      );
    }
    final bolum = _Bolum(kayit.key, kayit.value, benzersiz(kayit.value));
    final eskiSluglar = <String, int>{};
    final satirlar = ham.split('\n');
    final maskeli = kodBloklariniMaskele(ham).split('\n');
    var ilkIcerik = true;
    for (var i = 0; i < satirlar.length; i++) {
      final baslikEs = RegExp(
        r'^ {0,3}(#{1,6})[ \t]+(.+?)[ \t]*$',
      ).firstMatch(maskeli[i]);
      final setext = i + 1 < satirlar.length && maskeli[i].trim().isNotEmpty
          ? RegExp(r'^ {0,3}(=+|-+)[ \t]*$').firstMatch(maskeli[i + 1])
          : null;
      final derece = baslikEs != null
          ? baslikEs[1]!.length
          : setext != null
          ? (setext[1]![0] == '=' ? 1 : 2)
          : null;
      final yazi = baslikEs != null
          ? baslikEs[2]!.replaceFirst(RegExp(r'[ \t]+#+$'), '')
          : (setext != null ? satirlar[i].trim() : null);
      if (derece != null && yazi != null) {
        final slug = _slug(yazi);
        final no = eskiSluglar.update(slug, (n) => n + 1, ifAbsent: () => 0);
        final eski = no == 0 ? slug : '$slug-$no';
        if (ilkIcerik && derece == 1) {
          bolum.hedefler[eski] =
              bolum.ankor; // Kaynak belge başlığı bölüm başlığına gider.
        } else {
          bolum.hedefler[eski] = benzersiz(yazi);
          final yeniDerece = derece == 1 ? 3 : (derece + 1).clamp(3, 6);
          bolum.satirlar.add('${'#' * yeniDerece} $yazi');
          if (derece == 6) {
            uyar(kayit.key, 'H6 başlığı birleşik metinde H6 olarak korundu.');
          }
        }
        if (setext != null && baslikEs == null) i++;
      } else {
        bolum.satirlar.add(satirlar[i]);
      }
      // Kod çitleri de içeriktir; arkasındaki H1 belge başlığı sayılmaz.
      if (satirlar[i].trim().isNotEmpty) ilkIcerik = false;
    }
    bolumler.add(bolum);
  }
  final sonuc = StringBuffer('# $kod — $baslik\n');
  for (final bolum in bolumler) {
    final govde = bolum.satirlar.join('\n');
    final satirlar = govde.split('\n');
    final maskeli = kodBloklariniMaskele(govde).split('\n');
    final islenmis = <String>[];
    for (var i = 0; i < satirlar.length; i++) {
      if (maskeli[i].trim().isEmpty && satirlar[i].trim().isNotEmpty) {
        islenmis.add(satirlar[i]);
        continue;
      }
      islenmis.add(
        _kodDisiBaglantilar(
          satirlar[i],
          (hedef) =>
              _baglanti(hedef, bolum, bolumler, (m) => uyar(bolum.dosya, m)),
        ),
      );
    }
    sonuc.write(
      '\n## ${bolum.baslik}\n\n${islenmis.join('\n').replaceAll(RegExp(r'^([ \t]*\n)+|(\n[ \t]*)+$'), '')}\n',
    );
  }
  return sonuc.toString();
}

class _Bolum {
  final String dosya, baslik, ankor;
  final satirlar = <String>[];
  final hedefler = <String, String>{};
  _Bolum(this.dosya, this.baslik, this.ankor);
}

String _slug(String metin) => metin
    .toLowerCase()
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll(RegExp(r'[^\p{L}\p{N}_\s-]', unicode: true), '')
    .trim()
    .replaceAll(RegExp(r'\s'), '-');

String _baglanti(
  String metin,
  _Bolum kaynak,
  List<_Bolum> bolumler,
  void Function(String) uyar,
) {
  final uri = Uri.tryParse(metin);
  if (uri == null) {
    uyar('Bağlantı çözümlenemedi, korundu: $metin');
    return metin;
  }
  if (uri.hasScheme || uri.hasAuthority || metin.startsWith('/')) return metin;
  final yol = uri.path.replaceFirst(RegExp(r'^\./'), '');
  final es = bolumler
      .where((b) => b.dosya.toLowerCase() == yol.toLowerCase())
      .toList();
  final hedef = yol.isEmpty
      ? kaynak
      : es.isNotEmpty
      ? es.single
      : null;
  if (hedef != null && !uri.hasQuery) {
    final fragment = uri.fragment;
    if (fragment.isEmpty) return '#${Uri.encodeComponent(hedef.ankor)}';
    final yeni = hedef.hedefler[fragment];
    if (yeni != null) return '#${Uri.encodeComponent(yeni)}';
    uyar('Belge içi başlık bulunamadı; bağlantı korundu: $metin');
    return metin;
  }
  uyar(
    'Birleşik içerik dışında kalan göreli bağlantı kaynak ders klasörüne göre korundu; API URL’sine çevrilmedi: $metin',
  );
  return metin;
}

/// Satır içi kod, kaçışlar ve resim bağlantıları değiştirilmez.
String _kodDisiBaglantilar(String satir, String Function(String) donustur) {
  final cikti = StringBuffer();
  var i = 0;
  while (i < satir.length) {
    if (satir[i] == '\\' && i + 1 < satir.length) {
      cikti.write(satir.substring(i, i + 2));
      i += 2;
      continue;
    }
    if (satir[i] == '`') {
      var son = i;
      while (son < satir.length && satir[son] == '`') {
        son++;
      }
      final cit = satir.substring(i, son);
      final kapanis = satir.indexOf(cit, son);
      if (kapanis >= 0) {
        cikti.write(satir.substring(i, kapanis + cit.length));
        i = kapanis + cit.length;
        continue;
      }
    }
    final es = RegExp(
      r'^(!?\[[^\]\n]*\]\()(<[^>\n]+>|[^\s)]+)([^\n]*?\))',
    ).firstMatch(satir.substring(i));
    if (es != null) {
      final ham = es[2]!;
      final acili = ham.startsWith('<');
      final adres = acili ? ham.substring(1, ham.length - 1) : ham;
      final yeni = donustur(adres);
      // Gömmeyi sayfa içi bağlantıya dönüştürme.
      cikti.write(
        '${es[1]}${es[1]!.startsWith('!')
            ? ham
            : acili
            ? '<$yeni>'
            : yeni}${es[3]}',
      );
      i += es[0]!.length;
      continue;
    }
    // Referans bağlantı tanımı: [ad]: hedef "başlık"
    if (i == 0) {
      final ref = RegExp(
        r'^( {0,3}\[[^\]]+\]:\s*)(<[^>]+>|\S+)(.*)$',
      ).firstMatch(satir);
      if (ref != null) {
        final acili = ref[2]!.startsWith('<');
        final ham = acili ? ref[2]!.substring(1, ref[2]!.length - 1) : ref[2]!;
        final yeni = donustur(ham);
        return '${ref[1]}${acili ? '<$yeni>' : yeni}${ref[3]}';
      }
    }
    cikti.write(satir[i]);
    i++;
  }
  return cikti.toString();
}
