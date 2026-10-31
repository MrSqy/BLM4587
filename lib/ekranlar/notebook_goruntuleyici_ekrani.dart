import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../modeller/notebook.dart';

class NotebookGoruntuleyiciEkrani extends StatelessWidget {
  final NotebookBelgesi notebook;
  final String baslik;

  const NotebookGoruntuleyiciEkrani({
    super.key,
    required this.notebook,
    this.baslik = 'Notebook',
  });

  @override
  Widget build(BuildContext context) {
    final hucreler = notebook.hucreler
        .asMap()
        .entries
        .where(
          (kayit) =>
              kayit.value is MarkdownHucresi || kayit.value is KodHucresi,
        )
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(baslik)),
      body: hucreler.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Bu notebookta gösterilebilen markdown veya kod hücresi yok.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: hucreler.length,
              separatorBuilder: (context, indeks) => const SizedBox(height: 12),
              itemBuilder: (context, indeks) {
                final kayit = hucreler[indeks];
                return switch (kayit.value) {
                  MarkdownHucresi hucre => _MarkdownHucresiKarti(
                    key: ValueKey('markdown_${kayit.key}'),
                    hucre: hucre,
                  ),
                  KodHucresi hucre => _KodHucresiKarti(
                    key: ValueKey('kod_${kayit.key}'),
                    hucre: hucre,
                  ),
                  _ => const SizedBox.shrink(),
                };
              },
            ),
    );
  }
}

class _MarkdownHucresiKarti extends StatelessWidget {
  final MarkdownHucresi hucre;

  const _MarkdownHucresiKarti({super.key, required this.hucre});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: MarkdownBody(
          data: hucre.kaynak,
          selectable: true,
          imageBuilder: (uri, title, alt) => _gorselOlustur(uri, alt),
        ),
      ),
    );
  }

  Widget _gorselOlustur(Uri uri, String? alternatifMetin) {
    if (uri.scheme != 'attachment') {
      return Text(alternatifMetin ?? 'Harici görsel gösterilmiyor.');
    }

    final dosyaAdi = uri.path;
    final ek = hucre.ekler[dosyaAdi];
    if (ek is Map) {
      for (final kayit in ek.entries) {
        if (kayit.key is String &&
            (kayit.key as String).startsWith('image/') &&
            kayit.value is String) {
          try {
            return Image.memory(
              base64Decode(kayit.value as String),
              key: ValueKey('attachment_$dosyaAdi'),
              semanticLabel: alternatifMetin,
              errorBuilder: (context, error, stackTrace) =>
                  const Text('Notebook eki görüntülenemedi.'),
            );
          } on FormatException {
            break;
          }
        }
      }
    }
    return const Text('Notebook eki görüntülenemedi.');
  }
}

class _KodHucresiKarti extends StatelessWidget {
  final KodHucresi hucre;

  const _KodHucresiKarti({super.key, required this.hucre});

  @override
  Widget build(BuildContext context) {
    final calistirma = hucre.calistirmaSayisi == null
        ? 'Çalıştırılmadı'
        : 'Çalıştırma [${hucre.calistirmaSayisi}]';
    final renkler = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: renkler.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.code, size: 18),
                const SizedBox(width: 8),
                Text(calistirma),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: SelectionArea(
              child: Text(
                hucre.kaynak,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
