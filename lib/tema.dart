import 'package:flutter/material.dart';

const Color anaRenk = Color(0xFF18385F);

ThemeData _tema(Brightness brightness) {
  final koyu = brightness == Brightness.dark;
  final renkler =
      ColorScheme.fromSeed(seedColor: anaRenk, brightness: brightness).copyWith(
        primary: koyu ? const Color(0xFFA9C6EB) : anaRenk,
        surface: koyu ? const Color(0xFF1C2128) : const Color(0xFFFAFBFD),
        surfaceContainerLow: koyu
            ? const Color(0xFF252C35)
            : const Color(0xFFF0F2F6),
      );
  final base = ThemeData(useMaterial3: true, colorScheme: renkler);
  return base.copyWith(
    scaffoldBackgroundColor: renkler.surface,
    textTheme: base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium!.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      ),
      headlineSmall: base.textTheme.headlineSmall!.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.textTheme.titleLarge!.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.textTheme.titleMedium!.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.textTheme.bodyLarge!.copyWith(height: 1.5),
      bodyMedium: base.textTheme.bodyMedium!.copyWith(height: 1.45),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: renkler.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleSpacing: 24,
      elevation: 0,
      titleTextStyle: base.textTheme.headlineSmall!.copyWith(
        color: renkler.onSurface,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: renkler.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: renkler.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: renkler.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: renkler.surface,
      elevation: 0,
      indicatorColor: renkler.primaryContainer.withValues(alpha: 0.5),
    ),
    dividerTheme: DividerThemeData(
      color: renkler.outlineVariant,
      thickness: 0.6,
    ),
  );
}

final ThemeData acikTema = _tema(Brightness.light);
final ThemeData koyuTema = _tema(Brightness.dark);
