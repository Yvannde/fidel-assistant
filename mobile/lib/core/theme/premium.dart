import 'package:flutter/material.dart';

import 'app_colors.dart';

export 'app_colors.dart' show AppColors, ThemeTokens;

/// Langage visuel clinique — panneaux bordés, pas de bulles wellness.
abstract final class Premium {
  static const double radius = 12;
  static const double radiusSm = 8;
  static const double navHeight = 56;
  static const double navRadius = 28;
  static const double navClearance = 100;
  static const double screenPad = 16;

  static List<BoxShadow> cardShadow(bool dark) {
    if (dark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    }
    return const [];
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
    // Voile bleu très léger en haut à droite — pas de blob ambre.
    final blue = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: dark ? 0.14 : 0.08),
          AppColors.primary.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.9, -size.height * 0.04),
        radius: size.width * 0.55,
      ));
    canvas.drawRect(Offset.zero & size, blue);
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
    this.padding = const EdgeInsets.all(16),
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
        border: Border.all(color: tokens.border),
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
