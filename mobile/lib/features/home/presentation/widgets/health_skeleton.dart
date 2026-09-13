import 'package:flutter/material.dart';

import '../../../../core/theme/premium.dart';
import 'home_skeleton.dart';

/// Skeleton onglet Santé.
class HealthSkeleton extends StatelessWidget {
  const HealthSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HomeSkeleton(width: double.infinity, height: 160, radius: Premium.radius),
        const SizedBox(height: 18),
        const HomeSkeleton(width: 120, height: 14),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < 2; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: HomeSkeleton(
                  width: double.infinity,
                  height: 110,
                  radius: Premium.radiusSm,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < 2; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: HomeSkeleton(
                  width: double.infinity,
                  height: 110,
                  radius: Premium.radiusSm,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
