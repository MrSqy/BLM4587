import 'package:flutter/material.dart';

// Henüz yapılmamış sekmeler için ortak yer tutucu.
class YakindaIcerik extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final String aciklama;

  const YakindaIcerik({
    super.key,
    required this.ikon,
    required this.baslik,
    required this.aciklama,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ikon, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(baslik, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(aciklama, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
