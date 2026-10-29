/// Kod çitlerini, girintili kodu ve satır içi kodu değiştirmeden işler.
String markdownIsle(String metin, void Function(String) uyar) {
  final satirlar = metin.split('\n');
  String? cit;
  var uzunluk = 0;
  final sonuc = <String>[];
  for (final satir in satirlar) {
    final es = RegExp(r'^ {0,3}(`{3,}|~{3,})(.*)$').firstMatch(satir);
    if (cit != null) {
      sonuc.add(satir);
      if (es != null &&
          es[1]![0] == cit &&
          es[1]!.length >= uzunluk &&
          es[2]!.trim().isEmpty) {
        cit = null;
      }
      continue;
    }
    if (es != null) {
      cit = es[1]![0];
      uzunluk = es[1]!.length;
      sonuc.add(satir);
      continue;
    }
    if (satir.startsWith('    ') || satir.startsWith('\t')) {
      sonuc.add(satir);
      continue;
    }
    var yeni = satir.replaceFirstMapped(
      RegExp(r'^(\s*>\s*)\[!([\w-]+)\]([+-]?)(.*)$'),
      (m) =>
          '${m[1]}**${m[2]}${m[4]!.trim().isEmpty ? '' : ': ${m[4]!.trim()}'}**',
    );
    // Eş uzunluktaki backtick çiftleri içindeki metin aynen korunur.
    final tampon = StringBuffer();
    var i = 0;
    var uyariVerildi = false;
    while (i < yeni.length) {
      if (yeni[i] == '`') {
        var son = i;
        while (son < yeni.length && yeni[son] == '`') {
          son++;
        }
        final isaret = yeni.substring(i, son);
        final kapanis = yeni.indexOf(isaret, son);
        if (kapanis >= 0) {
          tampon.write(yeni.substring(i, kapanis + isaret.length));
          i = kapanis + isaret.length;
          continue;
        }
      }
      if (!uyariVerildi &&
          (yeni.startsWith('%%', i) ||
              RegExp(r'^==[^=]+==').hasMatch(yeni.substring(i)))) {
        uyar('Desteklenmeyen Obsidian yorum/vurgusu korundu.');
        uyariVerildi = true;
      }
      final kalan = yeni.substring(i);
      final wiki = RegExp(r'^(!?)\[\[([^\]\n]+)\]\]').firstMatch(kalan);
      if (wiki != null) {
        final parcalar = wiki[2]!.split('|');
        final hedef = parcalar.first;
        if (wiki[1] == '!' || hedef.contains('#^') || parcalar.length > 2) {
          uyar(
            'Desteklenmeyen Obsidian bağlantısı/gömmesi korundu: ${wiki[0]}',
          );
          tampon.write(wiki[0]);
        } else {
          final bolum = hedef.indexOf('#');
          var dosya = bolum < 0 ? hedef : hedef.substring(0, bolum);
          if (dosya.isNotEmpty && !RegExp(r'\.[a-zA-Z0-9]+$').hasMatch(dosya)) {
            dosya += '.md';
          }
          final adres = '$dosya${bolum < 0 ? '' : hedef.substring(bolum)}';
          tampon.write(
            '[${parcalar.length == 2 ? parcalar.last : hedef}](<${adres.replaceAll('>', '%3E')}>)',
          );
        }
        i += wiki[0]!.length;
        continue;
      }
      tampon.write(yeni[i]);
      i++;
    }
    yeni = tampon.toString();
    sonuc.add(yeni);
  }
  if (cit != null) uyar('Kapatılmamış Markdown kod bloğu.');
  return sonuc.join('\n');
}

/// Başlık aramalarında kod örneklerinin görev sayılmasını engeller.
String kodBloklariniMaskele(String metin) {
  String? cit;
  var uzunluk = 0;
  return metin
      .split('\n')
      .map((satir) {
        final es = RegExp(r'^ {0,3}(`{3,}|~{3,})(.*)$').firstMatch(satir);
        final kod =
            cit != null ||
            es != null ||
            satir.startsWith('    ') ||
            satir.startsWith('\t');
        if (es != null) {
          if (cit == null) {
            cit = es[1]![0];
            uzunluk = es[1]!.length;
          } else if (es[1]![0] == cit &&
              es[1]!.length >= uzunluk &&
              es[2]!.trim().isEmpty) {
            cit = null;
          }
        }
        return kod ? ' ' * satir.length : satir;
      })
      .join('\n');
}
