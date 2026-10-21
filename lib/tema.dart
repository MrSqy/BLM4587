import 'package:flutter/material.dart';

// Uygulamanın ana rengi; açık ve koyu tema bu renkten türetilir.
const Color anaRenk = Colors.indigo;

final ThemeData acikTema = ThemeData(
  colorSchemeSeed: anaRenk,
  brightness: Brightness.light,
);

final ThemeData koyuTema = ThemeData(
  colorSchemeSeed: anaRenk,
  brightness: Brightness.dark,
);
