/// Python dizgilerini ve yorumlarını maskeler; kaynak hiçbir zaman çalıştırılmaz.
String pythonMaskele(String kod) {
  final sonuc = StringBuffer();
  var i = 0;
  void bosalt(String s) => sonuc.write(s.replaceAll(RegExp(r'[^\n]'), ' '));
  while (i < kod.length) {
    if (kod[i] == '#') {
      final son = kod.indexOf('\n', i);
      final bitis = son < 0 ? kod.length : son;
      bosalt(kod.substring(i, bitis));
      i = bitis;
    } else if (kod[i] == '"' || kod[i] == "'") {
      final tirnak = kod[i];
      final uclu = kod.startsWith(tirnak * 3, i);
      final isaret = tirnak * (uclu ? 3 : 1);
      var son = i + isaret.length;
      while (son < kod.length) {
        if (kod[son] == '\\') {
          son += 2;
          continue;
        }
        if (kod.startsWith(isaret, son)) {
          son += isaret.length;
          break;
        }
        son++;
      }
      if (son > kod.length) son = kod.length;
      bosalt(kod.substring(i, son));
      i = son;
    } else {
      sonuc.write(kod[i]);
      i++;
    }
  }
  return sonuc.toString();
}

List<Map<String, Object>> testTanimlari(String kod) {
  final maskeli = pythonMaskele(kod);
  return RegExp(
        r'^[ \t]*(?:async\s+)?def\s+(test_gorev_(\d+)(?:_\w+)?)\s*\(',
        multiLine: true,
      )
      .allMatches(maskeli)
      .map(
        (m) => <String, Object>{
          'ad': m[1]!,
          'no': int.parse(m[2]!),
          'satir': '\n'.allMatches(maskeli.substring(0, m.start)).length + 1,
        },
      )
      .toList();
}
