import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../modeller/notebook.dart';
import '../modeller/notebook_duzenleyici.dart';
import 'notebook_ciktilari.dart';
import 'notebook_hucre_duzenleyici.dart';

/// Uygulamaya gömülü örnek notebook'u açar. Notebook API'si gelene kadar
/// kayıtlı çıktıların gösterimini ve hücre düzenlemeyi denemek içindir.
class OrnekNotebookEkrani extends StatefulWidget {
  final Future<NotebookBelgesi> Function()? yukleyici;

  const OrnekNotebookEkrani({super.key, this.yukleyici});

  @override
  State<OrnekNotebookEkrani> createState() => _OrnekNotebookEkraniState();
}

class _OrnekNotebookEkraniState extends State<OrnekNotebookEkrani> {
  late final Future<NotebookBelgesi> _notebook =
      (widget.yukleyici ?? _varsayilanYukleyici)();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NotebookBelgesi>(
      future: _notebook,
      builder: (context, durum) {
        if (durum.hasData) {
          return NotebookGoruntuleyiciEkrani(
            notebook: durum.data!,
            baslik: 'Örnek notebook',
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Örnek notebook')),
          body: Center(
            child: durum.hasError
                ? const Text('Notebook açılamadı.')
                : const CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  static Future<NotebookBelgesi> _varsayilanYukleyici() => rootBundle
      .loadString('assets/ornek_notebook.ipynb')
      .then(NotebookBelgesi.fromJsonString);
}

/// Notebook'u gösterir. Sağ üstteki düğme düzenleme modunu açar (4.3): hücre
/// ekleme, silme, taşıma ve kaynak düzenleme. Değişiklikler bellekte tutulur.
class NotebookGoruntuleyiciEkrani extends StatefulWidget {
  final NotebookBelgesi notebook;
  final String baslik;

  const NotebookGoruntuleyiciEkrani({
    super.key,
    required this.notebook,
    this.baslik = 'Notebook',
  });

  @override
  State<NotebookGoruntuleyiciEkrani> createState() =>
      _NotebookGoruntuleyiciEkraniState();
}

class _NotebookGoruntuleyiciEkraniState
    extends State<NotebookGoruntuleyiciEkrani> {
  late final NotebookDuzenleyici _duzenleyici = NotebookDuzenleyici(
    widget.notebook,
  );
  final Map<int, TextEditingController> _denetleyiciler = {};
  bool _duzenleme = false;

  @override
  void dispose() {
    for (final denetleyici in _denetleyiciler.values) {
      denetleyici.dispose();
    }
    _duzenleyici.dispose();
    super.dispose();
  }

  static bool _gorunur(NotebookHucresi hucre) =>
      hucre is MarkdownHucresi || hucre is KodHucresi;

  // Ham hücreler gösterilmez; taşıma bir sonraki/önceki görünür hücreyle yer değiştirir.
  int? _komsuGorunur(int indeks, int yon) {
    final hucreler = _duzenleyici.hucreler;
    for (var i = indeks + yon; i >= 0 && i < hucreler.length; i += yon) {
      if (_gorunur(hucreler[i])) return i;
    }
    return null;
  }

  TextEditingController _denetleyici(int indeks) {
    final anahtar = _duzenleyici.anahtar(indeks);
    return _denetleyiciler.putIfAbsent(
      anahtar,
      () => TextEditingController(text: _duzenleyici.hucreler[indeks].kaynak),
    );
  }

  void _ekle(int indeks, YeniHucreTuru tur) => _duzenleyici.ekle(indeks, tur);

  void _sil(int indeks) {
    final silinen = _duzenleyici.sil(indeks);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Hücre silindi.'),
          action: SnackBarAction(
            label: 'Geri al',
            onPressed: () => _duzenleyici.geriAl(silinen),
          ),
        ),
      );
  }

  Future<void> _hucreTuruSecVeEkle(int indeks) async {
    final tur = await showModalBottomSheet<YeniHucreTuru>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Kod hücresi'),
              onTap: () => Navigator.pop(context, YeniHucreTuru.kod),
            ),
            ListTile(
              leading: const Icon(Icons.notes),
              title: const Text('Markdown hücresi'),
              onTap: () => Navigator.pop(context, YeniHucreTuru.markdown),
            ),
          ],
        ),
      ),
    );
    if (tur != null) _ekle(indeks, tur);
  }

  Future<void> _cikisiOnayla() async {
    final cik = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Değişiklikler kaybolacak'),
        content: const Text(
          'Notebook üzerindeki düzenlemeler henüz kaydedilmiyor. Çıkmak istiyor musun?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çık'),
          ),
        ],
      ),
    );
    if (cik == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _duzenleyici,
      builder: (context, _) {
        final hucreler = _duzenleyici.hucreler;
        final gorunurler = [
          for (var i = 0; i < hucreler.length; i++)
            if (_gorunur(hucreler[i])) i,
        ];
        return PopScope(
          canPop: !_duzenleyici.degisti,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _cikisiOnayla();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(widget.baslik),
              actions: [
                IconButton(
                  key: const ValueKey('notebookDuzenle'),
                  tooltip: _duzenleme ? 'Düzenlemeyi bitir' : 'Düzenle',
                  onPressed: () => setState(() => _duzenleme = !_duzenleme),
                  icon: Icon(_duzenleme ? Icons.check : Icons.edit_outlined),
                ),
              ],
            ),
            floatingActionButton: _duzenleme
                ? FloatingActionButton.extended(
                    key: const ValueKey('hucreEkle'),
                    onPressed: () => _hucreTuruSecVeEkle(hucreler.length),
                    icon: const Icon(Icons.add),
                    label: const Text('Hücre ekle'),
                  )
                : null,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_duzenleyici.degisti)
                  Container(
                    key: const ValueKey('kaydedilmediUyarisi'),
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: const Text(
                      'Değişiklikler bu ekranda tutuluyor, henüz kaydedilmiyor.',
                    ),
                  ),
                Expanded(
                  child: gorunurler.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _duzenleme
                                  ? 'Notebook boş. Aşağıdaki düğmeyle hücre ekle.'
                                  : 'Bu notebookta gösterilebilen markdown veya kod hücresi yok.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            16,
                            16,
                            _duzenleme ? 96 : 16,
                          ),
                          itemCount: gorunurler.length,
                          separatorBuilder: (context, indeks) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, sira) {
                            final indeks = gorunurler[sira];
                            final hucre = hucreler[indeks];
                            if (_duzenleme) {
                              return _duzenlemeKarti(indeks, sira);
                            }
                            return switch (hucre) {
                              MarkdownHucresi hucre => _MarkdownHucresiKarti(
                                key: ValueKey('markdown_$indeks'),
                                hucre: hucre,
                              ),
                              KodHucresi hucre => _KodHucresiKarti(
                                key: ValueKey('kod_$indeks'),
                                hucre: hucre,
                              ),
                              _ => const SizedBox.shrink(),
                            };
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _duzenlemeKarti(int indeks, int sira) {
    final anahtar = _duzenleyici.anahtar(indeks);
    final onceki = _komsuGorunur(indeks, -1);
    final sonraki = _komsuGorunur(indeks, 1);
    return DuzenlenebilirHucreKarti(
      key: ValueKey('duzenle_$anahtar'),
      hucre: _duzenleyici.hucreler[indeks],
      denetleyici: _denetleyici(indeks),
      sira: sira + 1,
      yukariTasi: onceki == null
          ? null
          : () => _duzenleyici.tasi(indeks, onceki),
      asagiTasi: sonraki == null
          ? null
          : () => _duzenleyici.tasi(indeks, sonraki),
      sil: () => _sil(indeks),
      altinaEkle: (tur) => _ekle(indeks + 1, tur),
      kaynakDegisti: (kaynak) {
        final guncel = _duzenleyici.anahtarIndeksi(anahtar);
        if (guncel >= 0) _duzenleyici.kaynakGuncelle(guncel, kaynak);
      },
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
          NotebookCiktilari(ciktilar: hucre.ciktilar),
        ],
      ),
    );
  }
}
