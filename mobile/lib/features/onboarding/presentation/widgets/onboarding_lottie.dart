import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// JSON officiels LottieFiles.com, joués via le renderer Flutter (`lottie`).
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

    return SizedBox(
      height: size,
      width: size,
      child: Lottie.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        repeat: true,
        errorBuilder: (_, __, ___) => Icon(
          fallbackIcon,
          size: size * 0.42,
          color: scheme.primary.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}
