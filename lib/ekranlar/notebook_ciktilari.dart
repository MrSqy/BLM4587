import 'dart:convert';

import 'package:flutter/material.dart';

import '../modeller/notebook.dart';

/// Kod hücresinin notebook dosyasında kayıtlı çıktıları: metin, tablo, görsel, hata.
class NotebookCiktilari extends StatelessWidget {
  final List<NotebookCiktisi> ciktilar;

  const NotebookCiktilari({super.key, required this.ciktilar});

  @override
  Widget build(BuildContext context) {
    if (ciktilar.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        for (final (indeks, cikti) in ciktilar.indexed)
          Padding(
            key: ValueKey('cikti_$indeks'),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: switch (cikti) {
              AkisCiktisi c => _MetinCiktisi(
                metin: c.metin,
                hata: c.akisAdi == 'stderr',
              ),
              GosterimCiktisi c => _VeriCiktisi(veri: c.veri),
              CalistirmaSonucu c => _VeriCiktisi(veri: c.veri),
              HataCiktisi c => _MetinCiktisi(
                metin: [
                  '${c.hataAdi}: ${c.hataDegeri}',
                  ...c.iz.map(ansiKodlariniTemizle),
                ].join('\n'),
                hata: true,
              ),
            },
          ),
      ],
    );
  }
}

/// Jupyter traceback satırlarındaki renk kodlarını (ESC[...m) kaldırır.
String ansiKodlariniTemizle(String metin) =>
    metin.replaceAll(RegExp(r'\x1B\[[0-9;]*[A-Za-z]'), '');

/// HTML'deki ilk tabloyu satır/hücre listesine çevirir (ör. pandas DataFrame).
/// Tablo yoksa veya boşsa null döner.
List<List<String>>? htmlTablosunuOku(String html) {
  final tablo = RegExp(
    r'<table\b[^>]*>(.*?)</table>',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(html);
  if (tablo == null) {
    return null;
  }
  final satirlar = RegExp(
    r'<tr\b[^>]*>(.*?)</tr>',
    caseSensitive: false,
    dotAll: true,
  ).allMatches(tablo.group(1)!);
  final hucre = RegExp(
    r'<(t[hd])\b[^>]*>(.*?)</\1>',
    caseSensitive: false,
    dotAll: true,
  );
  final sonuc = [
    for (final satir in satirlar)
      [
        for (final h in hucre.allMatches(satir.group(1)!))
          _htmlMetni(h.group(2)!),
      ],
  ].where((satir) => satir.isNotEmpty).toList();
  return sonuc.isEmpty ? null : sonuc;
}

String _htmlMetni(String html) => html
    .replaceAll(RegExp(r'<[^>]+>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&amp;', '&')
    .trim();

/// nbformat'ta MIME değeri tek metin veya satır listesi olabilir.
String? _mimeMetni(dynamic deger) => switch (deger) {
  String metin => metin,
  List<dynamic> satirlar when satirlar.every((s) => s is String) =>
    satirlar.join(),
  _ => null,
};

class _VeriCiktisi extends StatelessWidget {
  final Map<String, dynamic> veri;

  const _VeriCiktisi({required this.veri});

  @override
  Widget build(BuildContext context) {
    for (final tur in const ['image/png', 'image/jpeg']) {
      final base64 = _mimeMetni(veri[tur]);
      if (base64 != null) {
        return _GorselCiktisi(base64: base64);
      }
    }
    final html = _mimeMetni(veri['text/html']);
    final tablo = html == null ? null : htmlTablosunuOku(html);
    if (tablo != null) {
      return _TabloCiktisi(satirlar: tablo);
    }
    final metin = _mimeMetni(veri['text/plain']);
    if (metin != null) {
      return _MetinCiktisi(metin: metin);
    }
    return Text(
      'Bu çıktı türü gösterilemiyor: ${veri.keys.join(', ')}',
      style: TextStyle(color: Theme.of(context).colorScheme.outline),
    );
  }
}

class _MetinCiktisi extends StatelessWidget {
  final String metin;
  final bool hata;

  const _MetinCiktisi({required this.metin, this.hata = false});

  @override
  Widget build(BuildContext context) {
    final renkler = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SelectableText(
        metin.trimRight(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          height: 1.4,
          color: hata ? renkler.error : null,
        ),
      ),
    );
  }
}

class _TabloCiktisi extends StatelessWidget {
  final List<List<String>> satirlar;

  const _TabloCiktisi({required this.satirlar});

  @override
  Widget build(BuildContext context) {
    final sutunSayisi = satirlar
        .map((s) => s.length)
        .reduce((a, b) => a > b ? a : b);
    List<String> doldur(List<String> satir) => [
      ...satir,
      for (var i = satir.length; i < sutunSayisi; i++) '',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 36,
        dataRowMinHeight: 32,
        dataRowMaxHeight: 40,
        columns: [
          for (final baslik in doldur(satirlar.first))
            DataColumn(
              label: Text(
                baslik,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
        rows: [
          for (final satir in satirlar.skip(1))
            DataRow(cells: [for (final h in doldur(satir)) DataCell(Text(h))]),
        ],
      ),
    );
  }
}

class _GorselCiktisi extends StatelessWidget {
  final String base64;

  const _GorselCiktisi({required this.base64});

  @override
  Widget build(BuildContext context) {
    const hataMetni = Text('Görsel çıktı görüntülenemedi.');
    try {
      final baytlar = base64Decode(base64.replaceAll(RegExp(r'\s'), ''));
      return Align(
        alignment: Alignment.centerLeft,
        child: Image.memory(
          baytlar,
          semanticLabel: 'Notebook görsel çıktısı',
          errorBuilder: (context, error, stackTrace) => hataMetni,
        ),
      );
    } on FormatException {
      return hataMetni;
    }
  }
}
