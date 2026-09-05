import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AppToastType { success, error, info }

/// Toast flottant épure — coins arrondis, couleur selon le type.
abstract final class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: _ToastBody(message: message, type: type),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        duration: duration,
      ),
    );
  }

  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) =>
      show(
        context,
        message: message,
        type: AppToastType.success,
        duration: duration,
      );

  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) =>
      show(
        context,
        message: message,
        type: AppToastType.error,
        duration: duration,
      );

  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) =>
      show(
        context,
        message: message,
        type: AppToastType.info,
        duration: duration,
      );
}

class _ToastBody extends StatelessWidget {
  const _ToastBody({required this.message, required this.type});

  final String message;
  final AppToastType type;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (type) {
      AppToastType.success => (
          AppColors.toastSuccessBg,
          AppColors.toastSuccessFg,
          Icons.check_circle_rounded,
        ),
      AppToastType.error => (
          AppColors.toastErrorBg,
          AppColors.toastErrorFg,
          Icons.error_rounded,
        ),
      AppToastType.info => (
          AppColors.toastInfoBg,
          AppColors.toastInfoFg,
          Icons.info_rounded,
        ),
    };

    return Material(
      color: bg,
      elevation: 0,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: fg, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
