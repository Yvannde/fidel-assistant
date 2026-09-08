import 'package:flutter/material.dart';

/// Courbe lissée d’une série de mesures : trait principal, aplat dégradé
/// dessous, et un second trait optionnel pour la diastolique.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    required this.surface,
    this.secondary,
    this.secondaryColor,
    this.height = 88,
  });

  final List<double> values;
  final List<double>? secondary;
  final Color color;
  final Color? secondaryColor;

  /// Couleur de la carte — sert d’anneau autour du dernier point.
  final Color surface;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return SizedBox(height: height);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _SparklinePainter(
              values: values,
              secondary: secondary,
              color: color,
              secondaryColor: secondaryColor ?? color.withValues(alpha: 0.45),
              surface: surface,
              progress: t,
            ),
          ),
        );
      },
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.secondary,
    required this.color,
    required this.secondaryColor,
    required this.surface,
    required this.progress,
  });

  final List<double> values;
  final List<double>? secondary;
  final Color color;
  final Color secondaryColor;
  final Color surface;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final all = [...values, ...?secondary];
    var min = all.reduce((a, b) => a < b ? a : b);
    var max = all.reduce((a, b) => a > b ? a : b);
    if ((max - min).abs() < 1e-9) {
      min -= 1;
      max += 1;
    } else {
      final pad = (max - min) * 0.18;
      min -= pad;
      max += pad;
    }

    const inset = 8.0;
    final usable = size.height - inset * 2;

    Offset pointAt(List<double> series, int i) {
      final dx = series.length == 1
          ? size.width / 2
          : size.width * (i / (series.length - 1));
      final norm = (series[i] - min) / (max - min);
      return Offset(dx, inset + usable * (1 - norm));
    }

    final points = [
      for (var i = 0; i < values.length; i++) pointAt(values, i),
    ];

    final linePath = _smoothPath(points);

    final fill = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0),
          ],
        ).createShader(Offset.zero & size),
    );

    final secondaryValues = secondary;
    if (secondaryValues != null && secondaryValues.length == values.length) {
      final secondaryPoints = [
        for (var i = 0; i < secondaryValues.length; i++)
          pointAt(secondaryValues, i),
      ];
      canvas.drawPath(
        _smoothPath(secondaryPoints),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = secondaryColor,
      );
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );

    if (points.length <= 8) {
      for (final p in points) {
        canvas.drawCircle(p, 2.5, Paint()..color = color.withValues(alpha: 0.4));
      }
    }

    canvas.restore();

    if (progress > 0.98) {
      final last = points.last;
      canvas.drawCircle(last, 6.5, Paint()..color = surface);
      canvas.drawCircle(last, 4.5, Paint()..color = color);
    }
  }

  /// Catmull-Rom converti en cubiques — évite les angles durs entre mesures.
  Path _smoothPath(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    if (pts.length == 1) {
      path.lineTo(pts.first.dx, pts.first.dy);
      return path;
    }

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
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.values != values ||
      old.secondary != secondary;
}
