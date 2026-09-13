import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'sparkline.dart';

/// Courbe compacte verte pour la carte hero Santé (données réelles uniquement).
class HealthMiniSparkline extends StatelessWidget {
  const HealthMiniSparkline({
    super.key,
    required this.values,
    this.secondary,
    this.width = 108,
    this.height = 76,
  });

  final List<double> values;
  final List<double>? secondary;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    const line = Color(0xFF86EFAC);

    return SizedBox(
      width: width,
      height: height,
      child: Sparkline(
        values: values,
        secondary: secondary,
        color: line,
        secondaryColor: line.withValues(alpha: 0.45),
        surface: AppColors.primaryDark,
        height: height,
        compact: true,
      ),
    );
  }
}
