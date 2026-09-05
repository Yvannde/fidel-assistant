import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import 'onboarding_lottie.dart';

/// Shell onboarding premium — progression + Lottie + CTA.
class OnboardingShell extends StatelessWidget {
  const OnboardingShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
    this.lottieAsset,
    this.lottieIcon = Icons.favorite_outline_rounded,
    this.onBack,
    this.primaryEnabled = true,
    this.busy = false,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String subtitle;
  final double progress;
  final Widget child;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? lottieAsset;
  final IconData lottieIcon;
  final VoidCallback? onBack;
  final bool primaryEnabled;
  final bool busy;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = ThemeTokens.of(context);
    final overlay =
        tokens.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        backgroundColor: tokens.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
                child: Row(
                  children: [
                    if (onBack != null)
                      IconButton(
                        onPressed: busy ? null : onBack,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.05, 1),
                          minHeight: 6,
                          backgroundColor: tokens.border,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  children: [
                    if (lottieAsset != null) ...[
                      Center(
                        child: OnboardingLottie(
                          asset: lottieAsset!,
                          fallbackIcon: lottieIcon,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: tokens.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),
                    child,
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed:
                          (!primaryEnabled || busy) ? null : onPrimary,
                      child: busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Text(primaryLabel),
                    ),
                    if (secondaryLabel != null && onSecondary != null) ...[
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: busy ? null : onSecondary,
                        child: Text(secondaryLabel!),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
