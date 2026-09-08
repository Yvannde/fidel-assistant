import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Anneau de progression des prises du jour — arc à extrémités rondes,
/// animé à chaque changement de valeur.
class DayRing extends StatelessWidget {
  const DayRing({
    super.key,
    required this.done,
    required this.total,
    required this.trackColor,
    required this.progressColor,
    required this.labelColor,
    this.size = 74,
    this.stroke = 7,
  });

  final int done;
  final int total;
  final Color trackColor;
  final Color progressColor;
  final Color labelColor;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final target = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: value,
              trackColor: trackColor,
              progressColor: progressColor,
              stroke: stroke,
            ),
            child: Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style.copyWith(
                        color: labelColor,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                  children: [
                    TextSpan(
                      text: '$done',
                      style: TextStyle(fontSize: size * 0.28),
                    ),
                    TextSpan(
                      text: '/$total',
                      style: TextStyle(
                        fontSize: size * 0.18,
                        color: labelColor.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.stroke,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = stroke / 2;
    final arcRect = rect.deflate(inset);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, track);

    if (progress <= 0) return;

    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = progressColor;
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor ||
      old.stroke != stroke;
}
