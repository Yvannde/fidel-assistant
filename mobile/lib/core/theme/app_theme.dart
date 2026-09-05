import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Thème Fidel — Satoshi + bleu primary, accessibilité prioritaire.
class AppTheme {
  static const String fontFamily = 'Satoshi';

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      secondary: AppColors.primarySoft,
      surface: AppColors.surface,
      error: AppColors.error,
    );

    final baseText = TextTheme(
      displayLarge: _satoshi(57, FontWeight.w700, AppColors.textPrimary),
      displayMedium: _satoshi(45, FontWeight.w700, AppColors.textPrimary),
      displaySmall: _satoshi(36, FontWeight.w700, AppColors.textPrimary),
      headlineLarge: _satoshi(32, FontWeight.w700, AppColors.textPrimary),
      headlineMedium: _satoshi(28, FontWeight.w700, AppColors.textPrimary),
      headlineSmall: _satoshi(24, FontWeight.w700, AppColors.textPrimary),
      titleLarge: _satoshi(22, FontWeight.w700, AppColors.textPrimary),
      titleMedium: _satoshi(16, FontWeight.w600, AppColors.textPrimary),
      titleSmall: _satoshi(14, FontWeight.w600, AppColors.textPrimary),
      bodyLarge: _satoshi(16, FontWeight.w400, AppColors.textPrimary),
      bodyMedium: _satoshi(14, FontWeight.w400, AppColors.textPrimary),
      bodySmall: _satoshi(12, FontWeight.w400, AppColors.textSecondary),
      labelLarge: _satoshi(16, FontWeight.w600, AppColors.textPrimary),
      labelMedium: _satoshi(12, FontWeight.w500, AppColors.textSecondary),
      labelSmall: _satoshi(11, FontWeight.w500, AppColors.textSecondary),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: baseText,
      primaryTextTheme: baseText.apply(
        bodyColor: AppColors.textOnPrimary,
        displayColor: AppColors.textOnPrimary,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
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
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: AppColors.border, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: _satoshi(15, FontWeight.w600, AppColors.textPrimary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: _satoshi(14, FontWeight.w600, AppColors.primary),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.surface;
        }),
        checkColor: WidgetStateProperty.all(AppColors.textOnPrimary),
        side: const BorderSide(color: AppColors.divider, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        hintStyle: _satoshi(15, FontWeight.w400, AppColors.textSecondary),
        labelStyle: _satoshi(14, FontWeight.w500, AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        contentTextStyle: TextStyle(color: AppColors.textPrimary),
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
