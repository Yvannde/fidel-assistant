import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// JSON officiels LottieFiles.com, joués via le renderer Flutter (`lottie`).
/// Le player natif `dotlottie_flutter` est une Platform View : elle disparaît
/// derrière un clip / Transform (feuille onboarding).
class OnboardingLottie extends StatelessWidget {
  const OnboardingLottie({
    super.key,
    required this.asset,
    required this.fallbackIcon,
    this.size = 188,
  });

  final String asset;
  final IconData fallbackIcon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final well = scheme.brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9);

    return SizedBox(
      height: size,
      width: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: well,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Lottie.asset(
            asset,
            width: size - 16,
            height: size - 16,
            fit: BoxFit.contain,
            repeat: true,
            errorBuilder: (_, __, ___) => Icon(
              fallbackIcon,
              size: size * 0.42,
              color: scheme.primary.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );
  }
}
