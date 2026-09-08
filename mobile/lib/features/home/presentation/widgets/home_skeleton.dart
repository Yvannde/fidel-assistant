import 'package:flutter/material.dart';

import '../../../../core/theme/premium.dart';

/// Blocs pulsants — même silhouette que le contenu, zéro fausse donnée.
class HomeSkeleton extends StatefulWidget {
  const HomeSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.radius,
  });

  final double width;
  final double height;
  final double? radius;

  @override
  State<HomeSkeleton> createState() => _HomeSkeletonState();
}

class _HomeSkeletonState extends State<HomeSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final base = tokens.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFE8EEF5);
    final peak = tokens.isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFD7E0EB);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          width: widget.width == double.infinity ? null : widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(base, peak, _ctrl.value),
            borderRadius: BorderRadius.circular(
              widget.radius ?? Premium.radiusSm,
            ),
          ),
        );
      },
    );
  }
}

/// Silhouette des deux sections principales pendant le premier chargement.
/// Le header a son propre skeleton — on ne le duplique pas ici.
class HomeDashboardSkeleton extends StatelessWidget {
  const HomeDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    HomeSkeleton(width: 120, height: 12),
                    SizedBox(height: 14),
                    HomeSkeleton(width: 90, height: 36),
                    SizedBox(height: 10),
                    HomeSkeleton(width: 70, height: 14),
                  ],
                ),
              ),
              const HomeSkeleton(width: 72, height: 72, radius: 36),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HomeSkeleton(width: 130, height: 14),
              const SizedBox(height: 8),
              const HomeSkeleton(width: double.infinity, height: 11),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: HomeSkeleton(
                        width: double.infinity,
                        height: 78,
                        radius: Premium.radiusSm,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
