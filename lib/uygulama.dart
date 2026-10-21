import 'package:flutter/material.dart';

import 'rotalar.dart';
import 'tema.dart';

class EgitimUygulamasi extends StatelessWidget {
  const EgitimUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Etkileşimli Eğitim Platformu',
      debugShowCheckedModeBanner: false,
      theme: acikTema,
      darkTheme: koyuTema,
      // Telefonun açık/koyu tema ayarını izler. Ayarlar ekranı 5. haftada eklenecek.
      themeMode: ThemeMode.system,
      initialRoute: Rotalar.anaIskelet,
      routes: Rotalar.tablo,
    );
  }
}
