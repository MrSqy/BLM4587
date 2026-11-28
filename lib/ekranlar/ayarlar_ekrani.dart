import 'package:flutter/material.dart';

import '../servisler/ayarlar_servisi.dart';

class AyarlarEkrani extends StatefulWidget {
  const AyarlarEkrani({super.key});

  @override
  State<AyarlarEkrani> createState() => _AyarlarEkraniState();
}

class _AyarlarEkraniState extends State<AyarlarEkrani> {
  bool _kaydediyor = false;

  Future<void> _kaydet(Future<void> Function() degistir) async {
    setState(() => _kaydediyor = true);
    try {
      await degistir();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ayar kaydedilemedi. Tekrar dene.')),
        );
      }
    } finally {
      if (mounted) setState(() => _kaydediyor = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ayarlar')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Text('Görünüm', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
        DropdownButtonFormField<ThemeMode>(
          key: ValueKey(ayarlarServisi.tema),
          initialValue: ayarlarServisi.tema,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Tema',
            prefixIcon: Icon(Icons.contrast),
          ),
          items: const [
            DropdownMenuItem(value: ThemeMode.system, child: Text('Sistem')),
            DropdownMenuItem(value: ThemeMode.light, child: Text('Açık')),
            DropdownMenuItem(value: ThemeMode.dark, child: Text('Koyu')),
          ],
          onChanged: _kaydediyor
              ? null
              : (tema) {
                  if (tema != null) {
                    _kaydet(() => ayarlarServisi.temayiSec(tema));
                  }
                },
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<double>(
          key: ValueKey(ayarlarServisi.yaziOlcegi),
          initialValue: ayarlarServisi.yaziOlcegi,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Yazı boyutu',
            prefixIcon: Icon(Icons.format_size),
          ),
          items: const [
            DropdownMenuItem(value: 1.0, child: Text('Standart')),
            DropdownMenuItem(value: 1.15, child: Text('Büyük')),
            DropdownMenuItem(value: 1.3, child: Text('Çok büyük')),
          ],
          onChanged: _kaydediyor
              ? null
              : (olcek) {
                  if (olcek != null) {
                    _kaydet(() => ayarlarServisi.yaziOlceginiSec(olcek));
                  }
                },
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yazı önizlemesi',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ders içeriklerini, görevleri ve notlarını bu boyutta okuyabilirsin.',
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
