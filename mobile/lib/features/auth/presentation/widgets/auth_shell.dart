import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

/// Layout auth : fond bleu [head.png] + feuille blanche arrondie.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.headerHeightFactor = 0.34,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final double headerHeightFactor;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final headerH = size.height * headerHeightFactor;
    final topPad = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: headerH + 40,
              child: ColoredBox(
                color: AppColors.primary,
                child: Image.asset(
                  'assets/images/head.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => const SizedBox.expand(),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  if (onBack != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: onBack,
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textOnPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  SizedBox(
                    height: math.max(
                      headerH - topPad - (onBack != null ? 48 : 16),
                      120,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _BrandMark(),
                          const SizedBox(height: 18),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: AppColors.textOnPrimary,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textOnPrimary
                                      .withValues(alpha: 0.88),
                                  height: 1.4,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Material(
                      color: AppColors.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      clipBehavior: Clip.antiAlias,
                      elevation: 0,
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Fidel',
      child: CustomPaint(
        size: const Size(42, 46),
        painter: _ShieldStarPainter(),
      ),
    );
  }
}

class _ShieldStarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round;

    final shield = Path()
      ..moveTo(size.width * 0.5, 1.5)
      ..lineTo(size.width - 2.5, size.height * 0.2)
      ..lineTo(size.width - 2.5, size.height * 0.52)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height + 1,
        2.5,
        size.height * 0.52,
      )
      ..lineTo(2.5, size.height * 0.2)
      ..close();

    canvas.drawPath(shield, stroke);

    final fill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final cx = size.width * 0.5;
    final cy = size.height * 0.4;
    final outerR = size.width * 0.16;
    final innerR = size.width * 0.055;
    final star = Path();
    for (var i = 0; i < 8; i++) {
      final r = i.isEven ? outerR : innerR;
      final a = (i * 45 - 90) * math.pi / 180;
      final p = Offset(cx + r * math.cos(a), cy + r * math.sin(a));
      if (i == 0) {
        star.moveTo(p.dx, p.dy);
      } else {
        star.lineTo(p.dx, p.dy);
      }
    }
    star.close();
    canvas.drawPath(star, fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
