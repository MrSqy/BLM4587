import 'package:flutter/material.dart';

import 'yakinda_icerik.dart';

// Ders tamamlama ve ilerleme çubukları 4. haftada bu ekrana gelecek.
class IlerlemeEkrani extends StatelessWidget {
  const IlerlemeEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return const YakindaIcerik(
      ikon: Icons.insights,
      baslik: 'İlerleme',
      aciklama: 'Tamamladığın dersler ve gönderim geçmişin burada görünecek.',
    );
  }
}
