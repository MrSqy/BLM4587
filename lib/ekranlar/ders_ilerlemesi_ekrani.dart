import 'package:flutter/material.dart';

import '../servisler/api_istemcisi.dart';
import '../servisler/oturum_servisi.dart';

class DersIlerlemesiEkrani extends StatefulWidget {
  const DersIlerlemesiEkrani({super.key});

  @override
  State<DersIlerlemesiEkrani> createState() => _DersIlerlemesiEkraniState();
}

class _DersIlerlemesiEkraniState extends State<DersIlerlemesiEkrani> {
  late final _oturum = oturumServisi;
  late final _hesap = _oturum.kullaniciId;
  late Future<List<_DersIlerlemesi>> _sonuc = _yukle();

  Future<List<_DersIlerlemesi>> _yukle() async {
    final data = await _oturum.api.iste('ilerlemeler') as List;
    return data
        .map((e) => _DersIlerlemesi.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ders ilerlemem')),
    body: ListenableBuilder(
      listenable: _oturum,
      builder: (context, _) {
        if (_hesap == null || _hesap != _oturum.kullaniciId) {
          return const Center(
            child: Text('İlerlemene erişmek için giriş yap.'),
          );
        }
        return FutureBuilder<List<_DersIlerlemesi>>(
          future: _sonuc,
          builder: (context, durum) {
            if (durum.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (durum.hasError) {
              final hata = durum.error;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hata is ApiHatasi
                            ? hata.mesaj
                            : 'Ders ilerlemesi okunamadı.',
                      ),
                      OutlinedButton(
                        onPressed: () => setState(() => _sonuc = _yukle()),
                        child: const Text('Tekrar dene'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final dersler = durum.data!;
            final tamamlanan = dersler.where((ders) => ders.tamamlandi).length;
            return RefreshIndicator(
              onRefresh: () async {
                final istek = _yukle();
                setState(() => _sonuc = istek);
                try {
                  await istek;
                } catch (_) {
                  /* FutureBuilder hatayı gösterir. */
                }
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    '$tamamlanan / ${dersler.length} ders tamamlandı',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  for (final ders in dersler)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${ders.kod} · ${ders.baslik}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(ders.etiket),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: ders.gecilen / ders.toplam,
                              semanticsLabel: ders.baslik,
                              semanticsValue: ders.etiket,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}

class _DersIlerlemesi {
  final String kod, baslik;
  final int gecilen, toplam;
  final bool tamamlandi;
  const _DersIlerlemesi(
    this.kod,
    this.baslik,
    this.gecilen,
    this.toplam,
    this.tamamlandi,
  );

  factory _DersIlerlemesi.fromJson(Map<String, dynamic> json) {
    final gecilen = json['gecilen'] as int;
    final toplam = json['toplam'] as int;
    if (toplam < 1 || gecilen < 0 || gecilen > toplam) {
      throw const FormatException('Geçersiz ders ilerlemesi.');
    }
    return _DersIlerlemesi(
      json['kod'] as String,
      json['baslik'] as String,
      gecilen,
      toplam,
      json['tamamlandi'] as bool,
    );
  }

  String get etiket => tamamlandi
      ? 'Tamamlandı'
      : gecilen == 0
      ? 'Henüz başlanmadı'
      : '$gecilen / $toplam görev';
}
