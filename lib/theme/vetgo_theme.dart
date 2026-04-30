import 'package:flutter/material.dart';

/// Colores de marca Vetgo.
abstract final class VetgoColors {
  /// Modo claro: verde principal.
  static const Color lightGreen = Color(0xFF4C956C);

  /// Modo oscuro: acento (reemplaza el verde en controles destacados).
  static const Color darkAccent = Color(0xFFECF39E);
}

abstract final class VetgoTheme {
  static ThemeData light() {
    const primary = VetgoColors.lightGreen;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFC8E6D4),
        onPrimaryContainer: const Color(0xFF0D2818),
        secondary: const Color(0xFF3A7A55),
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: const Color(0xFF1C1B1F),
        surfaceContainerHighest: const Color(0xFFE8F5EC),
        outline: const Color(0xFF6B8576),
        error: const Color(0xFFBA1A1A),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7FAF8),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData dark() {
    const accent = VetgoColors.darkAccent;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: accent,
        onPrimary: const Color(0xFF0D1F14),
        primaryContainer: const Color(0xFF2D4A38),
        onPrimaryContainer: accent,
        secondary: const Color(0xFF8FB89E),
        onSecondary: const Color(0xFF0D1F14),
        surface: const Color(0xFF121212),
        onSurface: const Color(0xFFE6E6E6),
        surfaceContainerHighest: const Color(0xFF2C2C2C),
        outline: const Color(0xFF8A9B91),
        error: const Color(0xFFFFB4AB),
        onError: const Color(0xFF690005),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: accent,
      ),
    );
  }
}
