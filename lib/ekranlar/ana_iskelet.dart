import 'package:flutter/material.dart';

import 'ana_sayfa.dart';
import 'egitimler_ekrani.dart';
import 'ilerleme_ekrani.dart';
import 'profil_ekrani.dart';

// Alt menülü ana iskelet. Her sekme ayrı bir ekran sınıfıdır.
class AnaIskelet extends StatefulWidget {
  const AnaIskelet({super.key});

  @override
  State<AnaIskelet> createState() => _AnaIskeletState();
}

class _AnaIskeletState extends State<AnaIskelet> {
  int _seciliIndeks = 0;

  static const List<String> _basliklar = [
    'Ana Sayfa',
    'Eğitimler',
    'İlerleme',
    'Profil',
  ];

  Widget _egitimler = const EgitimlerEkrani();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_basliklar[_seciliIndeks])),
      body: IndexedStack(
        index: _seciliIndeks,
        children: [
          AnaSayfa(
            kategoriSec: (id) => setState(() {
              _egitimler = EgitimlerEkrani(
                key: ValueKey(id),
                baslangicKategoriId: id,
              );
              _seciliIndeks = 1;
            }),
          ),
          _egitimler,
          IlerlemeEkrani(etkin: _seciliIndeks == 2),
          const ProfilEkrani(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _seciliIndeks,
        onDestinationSelected: (indeks) =>
            setState(() => _seciliIndeks = indeks),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Eğitimler',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'İlerleme',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
