import 'package:flutter/material.dart';

import 'rotalar.dart';
import 'servisler/ayarlar_servisi.dart';
import 'tema.dart';

class EgitimUygulamasi extends StatelessWidget {
  const EgitimUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ayarlarServisi,
      builder: (context, _) => MaterialApp(
        title: 'Etkileşimli Eğitim Platformu',
        debugShowCheckedModeBanner: false,
        theme: acikTema,
        darkTheme: koyuTema,
        themeMode: ayarlarServisi.tema,
        initialRoute: Rotalar.anaIskelet,
        routes: Rotalar.tablo,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          final tercih = ayarlarServisi.yaziOlcegi;
          return MediaQuery(
            data: media.copyWith(
              textScaler: tercih == 1
                  ? media.textScaler
                  : _YaziOlcegi(media.textScaler, tercih),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}

class _YaziOlcegi extends TextScaler {
  final TextScaler sistem;
  final double tercih;
  const _YaziOlcegi(this.sistem, this.tercih);

  @override
  double scale(double fontSize) => sistem.scale(fontSize) * tercih;

  @override
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) =>
      other is _YaziOlcegi && other.sistem == sistem && other.tercih == tercih;

  @override
  int get hashCode => Object.hash(sistem, tercih);
}
