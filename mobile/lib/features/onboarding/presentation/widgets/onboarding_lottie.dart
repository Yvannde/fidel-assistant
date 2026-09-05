import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Lottie locale avec fallback icône si asset manquant / invalide.
class OnboardingLottie extends StatelessWidget {
  const OnboardingLottie({
    super.key,
    required this.asset,
    required this.fallbackIcon,
    this.size = 140,
  });

  final String asset;
  final IconData fallbackIcon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: size,
      width: size,
      child: Lottie.asset(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          fallbackIcon,
          size: size * 0.55,
          color: scheme.primary.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}
