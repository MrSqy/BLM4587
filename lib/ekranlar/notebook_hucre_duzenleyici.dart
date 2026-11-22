import 'package:flutter/material.dart';

import '../modeller/notebook.dart';
import '../modeller/notebook_duzenleyici.dart';
import 'notebook_ciktilari.dart';

/// 4.3: Düzenleme modunda tek hücrenin kartı: araç çubuğu + kaynak editörü.
/// Kod hücresinde kayıtlı çıktılar editörün altında görünmeye devam eder.
class DuzenlenebilirHucreKarti extends StatelessWidget {
  final NotebookHucresi hucre;
  final TextEditingController denetleyici;
  final int sira;
  final VoidCallback? yukariTasi;
  final VoidCallback? asagiTasi;
  final VoidCallback sil;
  final ValueChanged<YeniHucreTuru> altinaEkle;
  final ValueChanged<String> kaynakDegisti;

  const DuzenlenebilirHucreKarti({
    super.key,
    required this.hucre,
    required this.denetleyici,
    required this.sira,
    required this.yukariTasi,
    required this.asagiTasi,
    required this.sil,
    required this.altinaEkle,
    required this.kaynakDegisti,
  });

  @override
  Widget build(BuildContext context) {
    final kod = hucre is KodHucresi;
    final renkler = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: renkler.surfaceContainerHighest,
            padding: const EdgeInsets.only(left: 16, right: 4),
            child: Row(
              children: [
                Icon(kod ? Icons.code : Icons.notes, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${kod ? 'Kod' : 'Markdown'} · $sira',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  key: const ValueKey('hucreYukari'),
                  tooltip: 'Yukarı taşı',
                  onPressed: yukariTasi,
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  key: const ValueKey('hucreAsagi'),
                  tooltip: 'Aşağı taşı',
                  onPressed: asagiTasi,
                  icon: const Icon(Icons.arrow_downward),
                ),
                PopupMenuButton<YeniHucreTuru>(
                  key: const ValueKey('hucreAltinaEkle'),
                  tooltip: 'Altına hücre ekle',
                  icon: const Icon(Icons.add),
                  onSelected: altinaEkle,
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: YeniHucreTuru.kod,
                      child: Text('Altına kod hücresi'),
                    ),
                    PopupMenuItem(
                      value: YeniHucreTuru.markdown,
                      child: Text('Altına markdown hücresi'),
                    ),
                  ],
                ),
                IconButton(
                  key: const ValueKey('hucreSil'),
                  tooltip: 'Hücreyi sil',
                  onPressed: sil,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              key: const ValueKey('hucreKaynagi'),
              controller: denetleyici,
              onChanged: kaynakDegisti,
              minLines: 3,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              autocorrect: !kod,
              enableSuggestions: !kod,
              style: kod
                  ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      height: 1.5,
                    )
                  : null,
              decoration: InputDecoration(
                labelText: kod ? 'Python kodu' : 'Markdown metni',
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          if (kod)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextButton.icon(
                  key: const ValueKey('hucreDortBosluk'),
                  onPressed: () {
                    _dortBoslukEkle(denetleyici);
                    kaynakDegisti(denetleyici.text);
                  },
                  icon: const Icon(Icons.format_indent_increase),
                  label: const Text('4 boşluk ekle'),
                ),
              ),
            ),
          if (hucre case KodHucresi(:final ciktilar) when ciktilar.isNotEmpty)
            NotebookCiktilari(ciktilar: ciktilar),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static void _dortBoslukEkle(TextEditingController denetleyici) {
    final secim = denetleyici.selection;
    final bas = secim.isValid ? secim.start : denetleyici.text.length;
    final son = secim.isValid ? secim.end : bas;
    denetleyici.value = TextEditingValue(
      text: denetleyici.text.replaceRange(bas, son, '    '),
      selection: TextSelection.collapsed(offset: bas + 4),
    );
  }
}
