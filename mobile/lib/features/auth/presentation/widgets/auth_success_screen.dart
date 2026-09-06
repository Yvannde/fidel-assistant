import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

/// Écran succès premium — check vert, confettis discrets, CTA charte bleue.
class AuthSuccessScreen extends StatefulWidget {
  const AuthSuccessScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onContinue,
  });

  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onContinue;

  @override
  State<AuthSuccessScreen> createState() => _AuthSuccessScreenState();
}

class _AuthSuccessScreenState extends State<AuthSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.05, 0.7, curve: Curves.easeOutBack),
      ),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.15, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = ThemeTokens.of(context);
    final overlay = tokens.isDark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        backgroundColor: tokens.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: const _SuccessMark(),
                  ),
                ),
                const SizedBox(height: 36),
                SlideTransition(
                  position: _slide,
                  child: FadeTransition(
                    opacity: _fade,
                    child: Column(
                      children: [
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: tokens.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.subtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: tokens.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _fade,
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: widget.onContinue,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(widget.ctaLabel),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessMark extends StatelessWidget {
  const _SuccessMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      height: 168,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(168, 168),
            painter: _SoftConfettiPainter(),
          ),
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: 0.12),
            ),
          ),
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final colors = [
      AppColors.primary,
      AppColors.primarySoft,
      AppColors.success,
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
    ];

    final specs = <(double, double, double, int, bool)>[
      // angle, radius, length, colorIdx, isDash
      (0.35, 62, 7, 0, true),
      (1.1, 70, 5, 3, false),
      (1.9, 58, 8, 1, true),
      (2.6, 66, 5, 4, false),
      (3.4, 72, 7, 2, true),
      (4.2, 60, 5, 0, false),
      (4.9, 68, 8, 3, true),
      (5.6, 64, 5, 1, false),
    ];

    for (final (angle, radius, len, colorIdx, isDash) in specs) {
      final paint = Paint()
        ..color = colors[colorIdx].withValues(alpha: 0.85)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..style = isDash ? PaintingStyle.stroke : PaintingStyle.fill;

      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);

      if (isDash) {
        final dx = math.cos(angle + 0.6) * len / 2;
        final dy = math.sin(angle + 0.6) * len / 2;
        canvas.drawLine(
          Offset(x - dx, y - dy),
          Offset(x + dx, y + dy),
          paint,
        );
      } else {
        canvas.drawCircle(Offset(x, y), 2.4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
