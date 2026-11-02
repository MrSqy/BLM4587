import 'package:flutter/material.dart';

import 'uygulama.dart';
import 'servisler/oturum_servisi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await oturumServisi.hazirla();
  runApp(const EgitimUygulamasi());
}
