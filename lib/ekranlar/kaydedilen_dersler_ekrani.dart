import 'package:flutter/material.dart';

import '../modeller/egitim.dart';
import '../servisler/ders_notu_deposu.dart';
import '../servisler/egitim_servisi.dart';
import '../servisler/oturum_servisi.dart';
import 'ders_ekrani.dart';

class KaydedilenDerslerEkrani extends StatefulWidget {
  const KaydedilenDerslerEkrani({super.key});

  @override
  State<KaydedilenDerslerEkrani> createState() =>
      _KaydedilenDerslerEkraniState();
}

class _KaydedilenDerslerEkraniState extends State<KaydedilenDerslerEkrani> {
  late final _hesap = oturumServisi.kullaniciId;
  late Future<List<(Egitim, DersNotu)>> _kayitlar = _yukle();

  Future<List<(Egitim, DersNotu)>> _yukle() async {
    const depo = DersNotuDeposu();
    final hesap = _hesap;
    if (hesap == null) return [];
    final sunucu = oturumServisi.api.adres.toString();
    final kayitlar = await depo.liste(sunucu, hesap);
    if (kayitlar.isEmpty) return [];
    final dersler = await egitimServisi.egitimleriGetir();
    return [
      for (final ders in dersler)
        if (kayitlar[ders.id] case final not?) (ders, not),
    ];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kaydedilen dersler')),
    body: ListenableBuilder(
      listenable: oturumServisi,
      builder: (context, _) {
        if (_hesap == null || _hesap != oturumServisi.kullaniciId) {
          return const Center(
            child: Text('Kaydedilen dersler için giriş yap.'),
          );
        }
        return FutureBuilder<List<(Egitim, DersNotu)>>(
          future: _kayitlar,
          builder: (context, durum) {
            if (durum.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (durum.hasError) {
              return Center(
                child: OutlinedButton(
                  onPressed: () => setState(() => _kayitlar = _yukle()),
                  child: const Text('Dersler yüklenemedi. Tekrar dene.'),
                ),
              );
            }
            final kayitlar = durum.data!;
            if (kayitlar.isEmpty) {
              return const Center(child: Text('Henüz kayıtlı dersin yok.'));
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final (ders, not) in kayitlar)
                  ListTile(
                    leading: Icon(not.yerImi ? Icons.bookmark : Icons.notes),
                    title: Text('${ders.kod} · ${ders.baslik}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DersEkrani(ozet: ders),
                        ),
                      );
                      if (mounted && _hesap == oturumServisi.kullaniciId) {
                        setState(() => _kayitlar = _yukle());
                      }
                    },
                  ),
              ],
            );
          },
        );
      },
    ),
  );
}
