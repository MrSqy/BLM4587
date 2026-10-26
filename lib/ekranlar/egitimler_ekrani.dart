import 'package:flutter/material.dart';

import '../modeller/egitim.dart';
import '../modeller/kategori.dart';
import '../servisler/egitim_servisi.dart';

class EgitimlerEkrani extends StatefulWidget {
  final EgitimServisi? servis;

  const EgitimlerEkrani({super.key, this.servis});

  @override
  State<EgitimlerEkrani> createState() => _EgitimlerEkraniState();
}

class _EgitimlerEkraniState extends State<EgitimlerEkrani> {
  late Future<_EgitimVerisi> _veri;
  int? _kategoriId;

  @override
  void initState() {
    super.initState();
    _veri = _yukle();
  }

  Future<_EgitimVerisi> _yukle() async {
    final servis = widget.servis ?? egitimServisi;
    final kategoriler = await servis.kategorileriGetir();
    final egitimler = await servis.egitimleriGetir();
    return _EgitimVerisi(kategoriler, egitimler);
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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Eğitimler yüklenemedi. Lütfen tekrar deneyin.'),
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
          padding: const EdgeInsets.all(16),
          // Kategori alanı ve dersler aynı kaydırma alanını paylaşır.
          itemCount: 1 + (dersler.isEmpty ? 1 : dersler.length),
          itemBuilder: (context, indeks) {
            if (indeks == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kategoriler',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
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
                                      (240 *
                                          MediaQuery.textScalerOf(
                                            context,
                                          ).scale(1)))
                                  .floor()
                                  .clamp(1, 4),
                          mainAxisExtent:
                              150 * MediaQuery.textScalerOf(context).scale(1),
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
                                            child: Text(kategori.kisaltma),
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
                  const SizedBox(height: 8),
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
                subtitle: Text('${ders.kod} • ${ders.gorevler.length} görev'),
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
