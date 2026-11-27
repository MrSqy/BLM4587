import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

/// Ders ve görev metinleri aynı Markdown motoruyla gösterilir.
/// Kendi dikey kaydırıcısı yoktur; ders ekranının kaydırıcısını kullanır.
class DersIcerigi extends StatefulWidget {
  final String metin;
  final Future<bool> Function(String href)? onDersIciBaglanti;

  const DersIcerigi({super.key, required this.metin, this.onDersIciBaglanti});

  @override
  State<DersIcerigi> createState() => DersIcerigiState();
}

class DersIcerigiState extends State<DersIcerigi>
    with AutomaticKeepAliveClientMixin
    implements MarkdownBuilderDelegate {
  @override
  bool get wantKeepAlive => true;
  late List<md.Node> _dugumler;
  final _hedefler = <String, GlobalKey>{};
  final _basliklar = <md.Element, GlobalKey>{};
  final _tanimlayicilar = <GestureRecognizer>[];

  @override
  void initState() {
    super.initState();
    _ayristir();
  }

  @override
  void didUpdateWidget(DersIcerigi oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.metin != widget.metin) _ayristir();
  }

  void _ayristir() {
    _hedefler.clear();
    _basliklar.clear();
    _dugumler = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
      encodeHtml: false,
    ).parseLines(const LineSplitter().convert(widget.metin));
    void tara(md.Node dugum) {
      if (dugum is! md.Element) return;
      if (RegExp(r'^h[1-6]$').hasMatch(dugum.tag)) {
        final temel = _baslikKimligi(dugum.textContent);
        var kimlik = temel;
        var no = 0;
        while (_hedefler.containsKey(kimlik)) {
          kimlik = '$temel-${++no}';
        }
        final anahtar = GlobalKey(debugLabel: 'ders-baslik-$kimlik');
        _hedefler[kimlik] = anahtar;
        _basliklar[dugum] = anahtar;
      }
      // Kod içindeki # satırları başlık değildir; AST bunu zaten ayırır.
      for (final child in dugum.children ?? <md.Node>[]) {
        tara(child);
      }
    }

    _dugumler.forEach(tara);
  }

  /// Uri.fragment kodlamayı korur; yalnız bir kez çözer, '+' işaretini koruruz.
  Future<bool> basligaGit(String href) async {
    if (!mounted) return false;
    final uri = Uri.tryParse(href);
    if (uri == null || !href.startsWith('#')) return false;
    final String fragment;
    try {
      fragment = Uri.decodeComponent(uri.fragment);
    } on FormatException {
      return false;
    }
    final hedef = fragment.isEmpty
        ? context
        : (_hedefler[fragment] ?? _hedefler[_baslikKimligi(fragment)])
              ?.currentContext;
    if (!mounted || hedef == null) return false;
    await Scrollable.ensureVisible(
      hedef,
      alignment: 0.05,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 220),
    );
    return true;
  }

  Future<void> _baglanti(String? href) async {
    if (href == null || !mounted) return;
    if (href.startsWith('#')) {
      var bulundu = await basligaGit(href);
      if (!mounted) return;
      if (!bulundu) {
        bulundu = await widget.onDersIciBaglanti?.call(href) ?? false;
      }
      if (!mounted || bulundu) return;
      _bildir('Bu derste bağlantının hedef bölümü bulunamadı.');
      return;
    }
    final uri = Uri.tryParse(href);
    if (uri == null ||
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty) {
      _bildir('Bu dosya veya bağlantı uygulamada açılamıyor.');
      return;
    }
    // Dış URL veya başka ders dosyası, yerel başlık sanılarak açılmaz.
    // Tarayıcı başlatma bağımlılığı eklemeden URL görünür ve kopyalanabilir.
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dış bağlantı'),
        content: SingleChildScrollView(child: SelectableText(href)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Kapat'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: href));
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Bağlantıyı kopyala'),
          ),
        ],
      ),
    );
  }

  void _bildir(String mesaj) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(mesaj)));
  }

  @override
  GestureRecognizer createLink(String text, String? href, String title) {
    final tanimlayici = TapGestureRecognizer()..onTap = () => _baglanti(href);
    _tanimlayicilar.add(tanimlayici);
    return tanimlayici;
  }

  @override
  TextSpan formatText(MarkdownStyleSheet styleSheet, String code) =>
      TextSpan(style: styleSheet.code, text: code);

  void _tanimlayicilariTemizle() {
    for (final t in _tanimlayicilar) {
      t.dispose();
    }
    _tanimlayicilar.clear();
  }

  MarkdownBuilder _olusturucu(
    MarkdownStyleSheet stil, [
    Map<String, MarkdownElementBuilder> builders = const {},
  ]) => MarkdownBuilder(
    delegate: this,
    selectable: true,
    styleSheet: stil,
    imageDirectory: null,
    imageBuilder: null,
    checkboxBuilder: null,
    bulletBuilder: null,
    builders: builders,
    paddingBuilders: const {},
    listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.start,
    contextMenuBuilder: (context, editableTextState) =>
        AdaptiveTextSelectionToolbar.editableText(
          editableTextState: editableTextState,
        ),
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _tanimlayicilariTemizle();
    final tema = Theme.of(context);
    // Büyük yazı/erişilebilirlik değişince AST'nin metinleri yeniden oluşturulur.
    MediaQuery.textScalerOf(context);
    final stil = MarkdownStyleSheet.fromTheme(tema).copyWith(
      a: TextStyle(
        color: tema.colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      p: tema.textTheme.bodyLarge,
      blockSpacing: 14,
      code: tema.textTheme.bodyMedium!.copyWith(
        fontFamily: 'monospace',
        height: 1.5,
        color: tema.colorScheme.onSurface,
        backgroundColor: tema.colorScheme.surfaceContainerHighest,
      ),
      codeblockPadding: const EdgeInsets.all(12),
      codeblockDecoration: BoxDecoration(
        color: tema.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
    );
    final baslik = _BaslikOlusturucu(
      (element, yaziStili) => Semantics(
        key: _basliklar[element],
        header: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _olusturucu(
            stil.copyWith(p: yaziStili),
          ).build([md.Element('p', element.children)]),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _olusturucu(stil, {
        'pre': _KodOlusturucu(stil.code!),
        for (var i = 1; i <= 6; i++) 'h$i': baslik,
      }).build(_dugumler),
    );
  }

  @override
  void dispose() {
    _tanimlayicilariTemizle();
    super.dispose();
  }
}

/// Aktarım aracındaki Türkçe karakterleri koruyan başlık biçimiyle uyumlu.
String _baslikKimligi(String metin) => metin
    .toLowerCase()
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll(RegExp(r'[^\p{L}\p{N}_\s-]', unicode: true), '')
    .trim()
    .replaceAll(RegExp(r'\s'), '-');

class _BaslikOlusturucu extends MarkdownElementBuilder {
  final Widget Function(md.Element element, TextStyle? stil) olustur;
  _BaslikOlusturucu(this.olustur);

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) => olustur(element, preferredStyle);
}

class _KodOlusturucu extends MarkdownElementBuilder {
  final TextStyle stil;
  _KodOlusturucu(this.stil);

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) => _KodBlogu(kod: element.textContent, stil: stil);
}

class _KodBlogu extends StatefulWidget {
  final String kod;
  final TextStyle stil;
  const _KodBlogu({required this.kod, required this.stil});

  @override
  State<_KodBlogu> createState() => _KodBloguState();
}

class _KodBloguState extends State<_KodBlogu> {
  final _kaydirma = ScrollController();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          tooltip: 'Kodu kopyala',
          onPressed: () => Clipboard.setData(ClipboardData(text: widget.kod)),
          icon: const Icon(Icons.copy_outlined),
        ),
      ),
      Scrollbar(
        controller: _kaydirma,
        child: SingleChildScrollView(
          controller: _kaydirma,
          primary: false,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          // Düzenlenebilir/seçilebilir metin yatay sürüklemeyi yutmamalı.
          // Kodun tamamı üstteki düğmeyle, boşluklarıyla kopyalanır.
          child: Text(
            widget.kod,
            style: widget.stil,
            softWrap: false,
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    ],
  );

  @override
  void dispose() {
    _kaydirma.dispose();
    super.dispose();
  }
}
