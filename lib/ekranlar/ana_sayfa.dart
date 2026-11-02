import 'package:flutter/material.dart';

import '../modeller/egitim.dart';
import '../modeller/kategori.dart';
import '../servisler/egitim_servisi.dart';

class AnaSayfa extends StatefulWidget {
  final ValueChanged<int>? kategoriSec;
  const AnaSayfa({super.key, this.kategoriSec});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  // Future initState'te bir kez oluşturulur; her build'de yeniden istek atılmaz.
  late Future<_Ozet> _ozet;

  @override
  void initState() {
    super.initState();
    _ozet = _ozetiGetir();
  }

  Future<_Ozet> _ozetiGetir() async {
    final kategoriler = await egitimServisi.kategorileriGetir();
    final egitimler = await egitimServisi.egitimleriGetir();
    return _Ozet(kategoriler, egitimler);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Ozet>(
      future: _ozet,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Dersler yüklenemedi. Bağlantınızı kontrol edin.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => setState(() => _ozet = _ozetiGetir()),
                    child: const Text('Tekrar dene'),
                  ),
                ],
              ),
            ),
          );
        }
        final ozet = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Hoş geldin!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            const Text('Dersleri oku, alıştırmaları çöz, kodunu test et.'),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SayiKutusu(
                      sayi: ozet.kategoriler.length,
                      etiket: 'Kategori',
                    ),
                    _SayiKutusu(sayi: ozet.egitimler.length, etiket: 'Ders'),
                    _SayiKutusu(sayi: ozet.gorevSayisi, etiket: 'Görev'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Kategoriler', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final kategori in ozet.kategoriler)
              Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(kategori.kisaltma)),
                  title: Text(kategori.ad),
                  subtitle: Text(kategori.aciklama),
                  trailing: Text('${ozet.dersSayisi(kategori.id)} ders'),
                  onTap: widget.kategoriSec == null
                      ? null
                      : () => widget.kategoriSec!(kategori.id),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Ozet {
  final List<Kategori> kategoriler;
  final List<Egitim> egitimler;

  _Ozet(this.kategoriler, this.egitimler);

  int get gorevSayisi =>
      egitimler.fold(0, (toplam, e) => toplam + e.gorevSayisi);

  int dersSayisi(int kategoriId) =>
      egitimler.where((e) => e.kategoriId == kategoriId).length;
}

class _SayiKutusu extends StatelessWidget {
  final int sayi;
  final String etiket;

  const _SayiKutusu({required this.sayi, required this.etiket});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$sayi', style: Theme.of(context).textTheme.headlineMedium),
        Text(etiket),
      ],
    );
  }
}
