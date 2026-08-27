import 'package:flutter/material.dart';

/// Thème de base — accessibilité (contraste, tailles système) prioritaire.
class AppTheme {
  static ThemeData get light {
    final base = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F6B4C),
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
