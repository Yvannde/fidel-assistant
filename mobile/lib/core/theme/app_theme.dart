import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'premium.dart';

/// Thème Fidel — Satoshi + bleu primary, light + dark, accessibilité prioritaire.
class AppTheme {
  static const String fontFamily = 'Satoshi';

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final onSurface =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final onSurfaceVariant =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final border = isDark ? AppColors.borderDark : AppColors.border;
    final divider = isDark ? AppColors.dividerDark : AppColors.divider;
    final inputFill =
        isDark ? AppColors.surfaceElevatedDark : AppColors.surface;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      secondary: AppColors.primarySoft,
      onSecondary: AppColors.textOnPrimary,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      error: AppColors.error,
      outline: border,
      outlineVariant: divider,
    );

    final baseText = TextTheme(
      displayLarge: _satoshi(57, FontWeight.w700, onSurface),
      displayMedium: _satoshi(45, FontWeight.w700, onSurface),
      displaySmall: _satoshi(36, FontWeight.w700, onSurface),
      headlineLarge: _satoshi(32, FontWeight.w700, onSurface),
      headlineMedium: _satoshi(28, FontWeight.w700, onSurface),
      headlineSmall: _satoshi(24, FontWeight.w700, onSurface),
      titleLarge: _satoshi(22, FontWeight.w700, onSurface),
      titleMedium: _satoshi(16, FontWeight.w500, onSurface),
      titleSmall: _satoshi(14, FontWeight.w500, onSurface),
      bodyLarge: _satoshi(16, FontWeight.w400, onSurface),
      bodyMedium: _satoshi(14, FontWeight.w400, onSurface),
      bodySmall: _satoshi(12, FontWeight.w400, onSurfaceVariant),
      labelLarge: _satoshi(16, FontWeight.w500, onSurface),
      labelMedium: _satoshi(12, FontWeight.w500, onSurfaceVariant),
      labelSmall: _satoshi(11, FontWeight.w500, onSurfaceVariant),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      textTheme: baseText.apply(fontFamily: fontFamily),
      primaryTextTheme: baseText.apply(
        bodyColor: AppColors.textOnPrimary,
        displayColor: AppColors.textOnPrimary,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.surfaceDark : Premium.canvas(false),
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: _satoshi(16, FontWeight.w700, AppColors.textOnPrimary),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(color: border, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: _satoshi(15, FontWeight.w700, onSurface),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: _satoshi(14, FontWeight.w500, AppColors.primary),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return inputFill;
        }),
        checkColor: WidgetStateProperty.all(AppColors.textOnPrimary),
        side: BorderSide(color: divider, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        hintStyle: _satoshi(15, FontWeight.w400, onSurfaceVariant),
        labelStyle: _satoshi(14, FontWeight.w500, onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.borderFocus,
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.surfaceElevatedDark : AppColors.background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        contentTextStyle: TextStyle(color: onSurface),
      ),
    );
  }

  static TextStyle _satoshi(double size, FontWeight weight, Color color) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.35,
      letterSpacing: -0.2,
    );
  }
}
