import 'package:flutter/material.dart';

import 'yakinda_icerik.dart';

// Eğitim listesi ve kategori filtresi 2. haftada (2.2) bu ekrana gelecek.
class EgitimlerEkrani extends StatelessWidget {
  const EgitimlerEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return const YakindaIcerik(
      ikon: Icons.menu_book,
      baslik: 'Eğitimler',
      aciklama: 'Ders listesi ve kategori filtresi burada olacak.',
    );
  }
}
