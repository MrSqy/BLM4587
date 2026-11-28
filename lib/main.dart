import 'package:flutter/material.dart';

import 'uygulama.dart';
import 'servisler/ayarlar_servisi.dart';
import 'servisler/oturum_servisi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([oturumServisi.hazirla(), ayarlarServisi.hazirla()]);
  runApp(const EgitimUygulamasi());
}
