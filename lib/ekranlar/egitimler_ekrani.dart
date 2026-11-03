import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../servisler/api_istemcisi.dart';
import 'package:flutter/services.dart';

import '../modeller/egitim.dart';
import '../modeller/kategori.dart';
import '../modeller/notebook.dart';
import '../servisler/egitim_servisi.dart';
import 'notebook_goruntuleyici_ekrani.dart';
import 'ders_ekrani.dart';
import '../rotalar.dart';
import '../servisler/oturum_servisi.dart';

typedef NotebookYukleyici = Future<NotebookBelgesi> Function();

class EgitimlerEkrani extends StatefulWidget {
  final EgitimServisi? servis;
  final int? baslangicKategoriId;
  final NotebookYukleyici? notebookYukleyici;

  const EgitimlerEkrani({
    super.key,
    this.servis,
    this.baslangicKategoriId,
    this.notebookYukleyici,
  });

  @override
  State<EgitimlerEkrani> createState() => _EgitimlerEkraniState();
}

class _EgitimlerEkraniState extends State<EgitimlerEkrani> {
  late Future<_EgitimVerisi> _veri;
  int? _kategoriId;

  @override
  void initState() {
    super.initState();
    _kategoriId = widget.baslangicKategoriId;
    _veri = _yukle();
    oturumServisi.addListener(_oturumDegisti);
  }

  void _oturumDegisti() {
    if (mounted) setState(() => _veri = _yukle());
  }

  @override
  void dispose() {
    oturumServisi.removeListener(_oturumDegisti);
    super.dispose();
  }

  Future<_EgitimVerisi> _yukle() async {
    final servis = widget.servis ?? egitimServisi;
    final kategoriler = await servis.kategorileriGetir();
    final egitimler = await servis.egitimleriGetir();
    return _EgitimVerisi(kategoriler, egitimler);
  }

  Future<void> _dersAc(Egitim ders) async {
    if (widget.notebookYukleyici != null) {
      await _notebookAc(ders);
      return;
    }
    if (!ders.erisilebilir) {
      final devam = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(ders.baslik),
          content: Text(
            '${ders.ozet}\n\nHer eğitimin ilk dersi misafirlere açık. Bu derse devam etmek için giriş yap.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Müfredata dön'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Giriş yap'),
            ),
          ],
        ),
      );
      if (devam != true || !mounted) return;
      await Navigator.pushNamed(context, Rotalar.giris);
      if (!mounted || !oturumServisi.girisYapildi) return;
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DersEkrani(ozet: ders, servis: widget.servis),
      ),
    );
  }

  Future<void> _notebookAc(Egitim ders) async {
    try {
      final notebook =
          await (widget.notebookYukleyici?.call() ??
              rootBundle
                  .loadString('assets/ornek_notebook.ipynb')
                  .then(NotebookBelgesi.fromJsonString));
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => NotebookGoruntuleyiciEkrani(
            notebook: notebook,
            baslik: '${ders.kod} Notebook',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notebook açılamadı.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_EgitimVerisi>(
      future: _veri,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          if (kDebugMode) debugPrint('Ders yükleme hatası: ${snapshot.error}');
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    snapshot.error is ApiHatasi
                        ? (snapshot.error as ApiHatasi).mesaj
                        : 'Eğitimler yüklenemedi. Lütfen tekrar deneyin.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => setState(() {
                      _kategoriId = null;
                      _veri = _yukle();
                    }),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tekrar dene'),
                  ),
                ],
              ),
            ),
          );
        }
        final veri = snapshot.data!;
        final dersler = veri.egitimler
            .where((e) => _kategoriId == null || e.kategoriId == _kategoriId)
            .toList();
        return ListView.builder(
          key: const PageStorageKey('egitimListesi'),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          // Kategori alanı ve dersler aynı kaydırma alanını paylaşır.
          itemCount: 1 + (dersler.isEmpty ? 1 : dersler.length),
          itemBuilder: (context, indeks) {
            if (indeks == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Öğrenmeye devam et',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  ChoiceChip(
                    key: const ValueKey('tumKategoriler'),
                    label: const Text('Tümü'),
                    selected: _kategoriId == null,
                    onSelected: (_) => setState(() => _kategoriId = null),
                  ),
                  const SizedBox(height: 8),
                  if (veri.kategoriler.isEmpty)
                    const Text('Henüz kategori eklenmemiş.')
                  else
                    LayoutBuilder(
                      builder: (context, constraints) => GridView.builder(
                        shrinkWrap: true,
                        primary: false,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              (constraints.maxWidth /
                                      (150 *
                                          MediaQuery.textScalerOf(
                                            context,
                                          ).scale(1)))
                                  .floor()
                                  .clamp(1, 4),
                          mainAxisExtent:
                              174 * MediaQuery.textScalerOf(context).scale(1),
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: veri.kategoriler.length,
                        itemBuilder: (context, indeks) {
                          final kategori = veri.kategoriler[indeks];
                          final secili = _kategoriId == kategori.id;
                          final sayi = veri.egitimler
                              .where((e) => e.kategoriId == kategori.id)
                              .length;
                          return Semantics(
                            selected: secili,
                            child: Card(
                              color: secili
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.secondaryContainer
                                  : null,
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                key: ValueKey('kategori_${kategori.id}'),
                                onTap: () =>
                                    setState(() => _kategoriId = kategori.id),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Icon(
                                              kategori.kisaltma == 'PY'
                                                  ? Icons.code
                                                  : Icons.functions,
                                              size: 24,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                          ),
                                          if (secili)
                                            const Icon(
                                              Icons.check_circle,
                                              size: 20,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: Text(
                                          kategori.ad,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                      ),
                                      Text('$sayi ders'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Dersler (${dersler.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }
            if (dersler.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  _kategoriId == null
                      ? 'Henüz eğitim eklenmemiş.'
                      : 'Bu kategoride henüz eğitim yok.',
                ),
              );
            }
            final ders = dersler[indeks - 1];
            return Card(
              key: ValueKey('ders_${ders.id}'),
              child: ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(ders.baslik),
                subtitle: Text(
                  '${ders.kod} · ${ders.gorevSayisi} görev${ders.misafireAcik ? ' · İlk ders açık' : ''}',
                ),
                trailing: Icon(
                  !ders.erisilebilir ? Icons.lock_outline : Icons.chevron_right,
                ),
                onTap: () => _dersAc(ders),
              ),
            );
          },
        );
      },
    );
  }
}

class _EgitimVerisi {
  final List<Kategori> kategoriler;
  final List<Egitim> egitimler;

  const _EgitimVerisi(this.kategoriler, this.egitimler);
}
