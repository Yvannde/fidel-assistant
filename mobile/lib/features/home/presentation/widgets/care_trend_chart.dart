import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';

class CareChartPoint {
  const CareChartPoint({required this.value, required this.label});

  final double value;
  final String label;
}

/// Courbe style référence : ligne pastel soft, fill léger, curseur, heures.
class CareTrendChart extends StatelessWidget {
  const CareTrendChart({
    super.key,
    required this.points,
    this.height = 168,
  });

  final List<CareChartPoint> points;
  final double height;

  /// Teinte douce type référence (lavande / rose gris), pas le bleu CTA.
  static const _lineStart = Color(0xFFE8A0A8);
  static const _lineEnd = Color(0xFF9B8FB8);
  static const _fillTop = Color(0x339B8FB8);

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final surface = tokens.isDark ? tokens.elevated : const Color(0xFFF3F1F6);

    if (points.isEmpty) return SizedBox(height: height);

    final plot = points.length == 1
        ? [
            CareChartPoint(value: points.first.value, label: ''),
            points.first,
          ]
        : points;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) {
              return CustomPaint(
                painter: _CareTrendPainter(
                  points: plot,
                  surface: surface,
                  progress: t,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        _TimeAxis(points: points, color: tokens.textSecondary),
      ],
    );
  }
}

class _TimeAxis extends StatelessWidget {
  const _TimeAxis({required this.points, required this.color});

  final List<CareChartPoint> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[];
    if (points.length == 1) {
      labels.add(points.first.label);
    } else if (points.length == 2) {
      labels.addAll([points.first.label, points.last.label]);
    } else {
      labels
        ..add(points.first.label)
        ..add(points[points.length ~/ 2].label)
        ..add(points.last.label);
    }

    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const Spacer(),
          Text(
            labels[i],
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: 0.85),
            ),
          ),
        ],
      ],
    );
  }
}

class _CareTrendPainter extends CustomPainter {
  _CareTrendPainter({
    required this.points,
    required this.surface,
    required this.progress,
  });

  final List<CareChartPoint> points;
  final Color surface;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final values = [for (final p in points) p.value];
    var min = values.reduce(math.min);
    var max = values.reduce(math.max);
    if ((max - min).abs() < 1e-9) {
      min -= 1;
      max += 1;
    } else {
      final pad = (max - min) * 0.28;
      min -= pad;
      max += pad;
    }

    const top = 8.0;
    const bottom = 6.0;
    final usable = size.height - top - bottom;

    Offset at(int i) {
      final dx = size.width * (i / (points.length - 1).clamp(1, 999));
      final norm = (values[i] - min) / (max - min);
      return Offset(dx, top + usable * (1 - norm));
    }

    final pts = [for (var i = 0; i < points.length; i++) at(i)];
    final linePath = _smooth(pts);

    final fill = Path.from(linePath)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));

    canvas.drawPath(
      fill,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, top),
          Offset(0, size.height),
          [
            CareTrendChart._fillTop,
            const Color(0x009B8FB8),
          ],
        ),
    );

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, 0),
        [
          CareTrendChart._lineStart,
          CareTrendChart._lineEnd,
        ],
      );

    canvas.drawPath(linePath, linePaint);
    canvas.restore();

    if (progress > 0.96) {
      final last = pts.last;
      canvas.drawLine(
        Offset(last.dx, 0),
        Offset(last.dx, size.height),
        Paint()
          ..color = CareTrendChart._lineEnd.withValues(alpha: 0.45)
          ..strokeWidth = 1.2,
      );
      canvas.drawCircle(last, 7, Paint()..color = surface);
      canvas.drawCircle(
        last,
        6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = CareTrendChart._lineEnd,
      );
      canvas.drawCircle(last, 3.2, Paint()..color = CareTrendChart._lineEnd);
    }
  }

  Path _smooth(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    if (pts.length == 1) return path;
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = i == 0 ? pts[i] : pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i + 2 < pts.length ? pts[i + 2] : p2;
      path.cubicTo(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
        p2.dx,
        p2.dy,
      );
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _CareTrendPainter old) =>
      old.progress != progress || old.points != points;
}
