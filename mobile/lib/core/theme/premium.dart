import 'package:flutter/material.dart';

import 'app_colors.dart';

export 'app_colors.dart' show AppColors, ThemeTokens;

/// Langage visuel accueil — cartes flottantes, aube camerounaise, pas de score santé.
abstract final class Premium {
  static const double radius = 28;
  static const double radiusSm = 20;
  static const double navHeight = 60;
  static const double navClearance = 108;

  static List<BoxShadow> cardShadow(bool dark) {
    if (dark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
      ];
    }
    return [
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.07),
        blurRadius: 32,
        offset: const Offset(0, 16),
      ),
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.06),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ];
  }

  static Color canvas(bool dark) =>
      dark ? const Color(0xFF0B1220) : const Color(0xFFF4F7FB);
}

class DawnBackdrop extends StatelessWidget {
  const DawnBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: Premium.canvas(dark),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: CustomPaint(painter: _DawnPainter(dark: dark)),
          ),
          child,
        ],
      ),
    );
  }
}

class _DawnPainter extends CustomPainter {
  _DawnPainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final blue = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: dark ? 0.28 : 0.22),
          AppColors.primary.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.86, -size.height * 0.02),
        radius: size.width * 0.72,
      ));
    canvas.drawRect(Offset.zero & size, blue);

    final warm = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF59E0B).withValues(alpha: dark ? 0.12 : 0.16),
          const Color(0xFFF59E0B).withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * -0.05, size.height * 0.08),
        radius: size.width * 0.58,
      ));
    canvas.drawRect(Offset.zero & size, warm);
  }

  @override
  bool shouldRepaint(covariant _DawnPainter oldDelegate) =>
      oldDelegate.dark != dark;
}

class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tokens = ThemeTokens.of(context);
    final radius = BorderRadius.circular(Premium.radius);
    final bg = color ?? (dark ? tokens.elevated : Colors.white);

    final body = Padding(padding: padding, child: child);
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        boxShadow: Premium.cardShadow(dark),
      ),
      child: onTap == null
          ? body
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: radius,
                child: body,
              ),
            ),
    );
  }
}
