import 'package:flutter/material.dart';

/// Palette Fidel — bleu du header auth ([assets/images/head.png]).
abstract final class AppColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primarySoft = Color(0xFF3B82F6);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFE2E8F0);
  static const Color borderFocus = Color(0xFF2563EB);
  static const Color divider = Color(0xFFCBD5E1);

  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);

  // Toasts
  static const Color toastSuccessBg = Color(0xFFECFDF5);
  static const Color toastSuccessFg = Color(0xFF047857);
  static const Color toastErrorBg = Color(0xFFFEF2F2);
  static const Color toastErrorFg = Color(0xFFB91C1C);
  static const Color toastInfoBg = Color(0xFFEFF6FF);
  static const Color toastInfoFg = Color(0xFF1D4ED8);
}
