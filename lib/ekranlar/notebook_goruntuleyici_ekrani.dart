import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../modeller/notebook.dart';
import '../modeller/notebook_duzenleyici.dart';
import '../servisler/notebook_depolama.dart';
import '../servisler/oturum_servisi.dart';
import 'notebook_ciktilari.dart';
import 'notebook_hucre_duzenleyici.dart';

/// Örnek notebook'u ve cihazda saklanan kopyalarını açar.
class OrnekNotebookEkrani extends StatefulWidget {
  final Future<NotebookBelgesi> Function()? yukleyici;

  final NotebookDepolama? depolama;

  const OrnekNotebookEkrani({super.key, this.yukleyici, this.depolama});

  @override
  State<OrnekNotebookEkrani> createState() => _OrnekNotebookEkraniState();
}

class _OrnekNotebookEkraniState extends State<OrnekNotebookEkrani> {
  late final _oturum = oturumServisi;
  late NotebookDepolama _depolama;
  late Future<(NotebookBelgesi, NotebookYerelKopya?)> _notebook;
  String? _hesap;
  (NotebookBelgesi, NotebookYerelKopya)? _acilan;
  Key _editorAnahtari = UniqueKey();

  @override
  void initState() {
    super.initState();
    _hesap = _oturum.kullaniciId;
    _depolamayiAc();
    if (widget.depolama == null) _oturum.addListener(_oturumDegisti);
  }

  void _depolamayiAc() {
    _depolama =
        widget.depolama ??
        NotebookDepolama(sunucu: _oturum.api.adres.toString(), hesap: _hesap);
    _notebook = _baslangiciGetir(_depolama);
  }

  Future<(NotebookBelgesi, NotebookYerelKopya?)> _baslangiciGetir(
    NotebookDepolama depolama,
  ) async {
    if (widget.yukleyici case final yukle?) return (await yukle(), null);
    try {
      final taslak = await depolama.oku(NotebookYerelKopya.taslak);
      if (taslak != null) return (taslak, NotebookYerelKopya.taslak);
    } on Exception {
      // Örnek ve kayıtlı kopya açılabilir. Taslağı aç menüsü hatayı gösterir.
    }
    return (await _varsayilanYukleyici(), null);
  }

  void _oturumDegisti() {
    final yeniHesap = _oturum.kullaniciId;
    if (yeniHesap == _hesap) return;
    ScaffoldMessenger.maybeOf(context)?.removeCurrentSnackBar();
    setState(() {
      _hesap = yeniHesap;
      _acilan = null;
      _editorAnahtari = UniqueKey();
      _depolamayiAc();
    });
  }

  @override
  void dispose() {
    if (widget.depolama == null) _oturum.removeListener(_oturumDegisti);
    super.dispose();
  }

  void _yerelKopyayiGoster(NotebookBelgesi belge, NotebookYerelKopya kopya) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    setState(() {
      _acilan = (belge, kopya);
      _editorAnahtari = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(NotebookBelgesi, NotebookYerelKopya?)>(
      future: _notebook,
      builder: (context, durum) {
        if (durum.connectionState == ConnectionState.done && durum.hasData) {
          return NotebookGoruntuleyiciEkrani(
            key: _editorAnahtari,
            notebook: _acilan?.$1 ?? durum.data!.$1,
            baslik: switch (_acilan?.$2 ?? durum.data!.$2) {
              NotebookYerelKopya.kayit => 'Kayıtlı notebook',
              NotebookYerelKopya.taslak => 'Notebook taslağı',
              null => 'Örnek notebook',
            },
            depolama: _depolama,
            yerelKopyayiGoster: _yerelKopyayiGoster,
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

/// Notebook'u gösterir, düzenler ve yerel kopya işlemlerini sunar.
class NotebookGoruntuleyiciEkrani extends StatefulWidget {
  final NotebookBelgesi notebook;
  final String baslik;
  final NotebookDepolama? depolama;
  final void Function(NotebookBelgesi, NotebookYerelKopya)? yerelKopyayiGoster;

  const NotebookGoruntuleyiciEkrani({
    super.key,
    required this.notebook,
    this.baslik = 'Notebook',
    this.depolama,
    this.yerelKopyayiGoster,
  });

  @override
  State<NotebookGoruntuleyiciEkrani> createState() =>
      _NotebookGoruntuleyiciEkraniState();
}

enum _NotebookDosyaIslemi {
  kaydet('Cihaza kaydet', NotebookYerelKopya.kayit, yazma: true),
  taslakKaydet('Taslak olarak kaydet', NotebookYerelKopya.taslak, yazma: true),
  kaydiAc('Kaydedilen notebook’u aç', NotebookYerelKopya.kayit),
  taslagiAc('Taslağı aç', NotebookYerelKopya.taslak);

  final String etiket;
  final NotebookYerelKopya kopya;
  final bool yazma;

  const _NotebookDosyaIslemi(this.etiket, this.kopya, {this.yazma = false});
}

class _NotebookGoruntuleyiciEkraniState
    extends State<NotebookGoruntuleyiciEkrani> {
  late final NotebookDuzenleyici _duzenleyici = NotebookDuzenleyici(
    widget.notebook,
  );
  final Map<int, TextEditingController> _denetleyiciler = {};
  bool _duzenleme = false;
  bool _islemSuruyor = false;
  int _kaydedilenSurum = 0;

  bool get _kaydedilmemis => _duzenleyici.degisiklikSurumu != _kaydedilenSurum;

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
    if (tur != null && mounted) _ekle(indeks, tur);
  }

  Future<bool> _degisiklikleriBirakmayiOnayla({required bool cikis}) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Değişiklikler kaybolacak'),
            content: Text(
              cikis ? 'Kaydedilmemiş düzenlemeler var. Çıkmak istiyor musun?' : 'Kaydedilmemiş düzenlemeler var. Yine de bu kopyayı açmak istiyor musun?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(cikis ? 'Çık' : 'Aç'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _cikisiOnayla() async {
    if (await _degisiklikleriBirakmayiOnayla(cikis: true) && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _bildir(String mesaj) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mesaj)));
  }

  Future<void> _dosyaIslemi(_NotebookDosyaIslemi islem) async {
    final depolama = widget.depolama;
    if (depolama == null || _islemSuruyor) return;

    FocusScope.of(context).unfocus();
    setState(() => _islemSuruyor = true);
    final taslak = islem.kopya == NotebookYerelKopya.taslak;
    try {
      if (islem.yazma) {
        final surum = _duzenleyici.degisiklikSurumu;
        await depolama.yaz(islem.kopya, _duzenleyici.belge);
        if (!mounted) return;
        _kaydedilenSurum = surum;
        _bildir(taslak ? 'Taslak kaydedildi.' : 'Notebook cihaza kaydedildi.');
        return;
      }

      final belge = await depolama.oku(islem.kopya);
      if (!mounted) return;
      if (belge == null) {
        _bildir(taslak ? 'Henüz taslak yok.' : 'Henüz kayıtlı notebook yok.');
        return;
      }
      if (_kaydedilmemis &&
          !await _degisiklikleriBirakmayiOnayla(cikis: false)) {
        return;
      }
      if (mounted) widget.yerelKopyayiGoster?.call(belge, islem.kopya);
    } on FormatException {
      if (mounted) {
        _bildir(
          taslak ? 'Taslak dosyası okunamadı.' : 'Notebook dosyası okunamadı.',
        );
      }
    } on Exception {
      if (mounted) {
        _bildir(switch (islem) {
          _NotebookDosyaIslemi.kaydet => 'Notebook kaydedilemedi.',
          _NotebookDosyaIslemi.taslakKaydet => 'Taslak kaydedilemedi.',
          _NotebookDosyaIslemi.kaydiAc => 'Notebook açılamadı.',
          _NotebookDosyaIslemi.taslagiAc => 'Taslak açılamadı.',
        });
      }
    } finally {
      if (mounted) setState(() => _islemSuruyor = false);
    }
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
          canPop: !_kaydedilmemis && !_islemSuruyor,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !_islemSuruyor) _cikisiOnayla();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(widget.baslik),
              actions: [
                IconButton(
                  key: const ValueKey('notebookDuzenle'),
                  tooltip: _duzenleme ? 'Düzenlemeyi bitir' : 'Düzenle',
                  onPressed: _islemSuruyor
                      ? null
                      : () => setState(() => _duzenleme = !_duzenleme),
                  icon: Icon(_duzenleme ? Icons.check : Icons.edit_outlined),
                ),
                if (widget.depolama != null &&
                    widget.yerelKopyayiGoster != null)
                  PopupMenuButton<_NotebookDosyaIslemi>(
                    tooltip: 'Notebook dosyaları',
                    enabled: !_islemSuruyor,
                    icon: const Icon(Icons.folder_open_outlined),
                    onSelected: _dosyaIslemi,
                    itemBuilder: (_) => [
                      for (final islem in _NotebookDosyaIslemi.values)
                        PopupMenuItem(value: islem, child: Text(islem.etiket)),
                    ],
                  ),
              ],
            ),
            floatingActionButton: _duzenleme
                ? FloatingActionButton.extended(
                    key: const ValueKey('hucreEkle'),
                    onPressed: _islemSuruyor
                        ? null
                        : () => _hucreTuruSecVeEkle(hucreler.length),
                    icon: const Icon(Icons.add),
                    label: const Text('Hücre ekle'),
                  )
                : null,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_islemSuruyor && ModalRoute.isCurrentOf(context) == true)
                  const LinearProgressIndicator(),
                if (_kaydedilmemis)
                  Container(
                    key: const ValueKey('kaydedilmediUyarisi'),
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: const Text('Kaydedilmemiş değişiklikler var.'),
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
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontFamily: 'monospace', height: 1.5),
              ),
            ),
          ),
          NotebookCiktilari(ciktilar: hucre.ciktilar),
        ],
      ),
    );
  }
}
