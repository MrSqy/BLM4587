import 'package:flutter/material.dart';

class HakkindaEkrani extends StatelessWidget {
  const HakkindaEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hakkında')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Etkileşimli Eğitim Platformu',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Mühendislik Eğitimleri deposundaki dersleri okumak, alıştırmaları çözmek '
            've kodunu test etmek için mobil uygulama.',
          ),
          const SizedBox(height: 16),
          const Text('BLM4587 — Ankara Üniversitesi Bilgisayar Mühendisliği'),
          const SizedBox(height: 16),
          Text('Ekip', style: Theme.of(context).textTheme.titleMedium),
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Ramazan Yalçın'),
          ),
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Nisa Ataizi'),
          ),
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Baran Demir'),
          ),
        ],
      ),
    );
  }
}
