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

/// Silhouette : hero → KPIs+semaine → timeline (espacements 16/20).
class HomeDashboardSkeleton extends StatelessWidget {
  const HomeDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              HomeSkeleton(width: 100, height: 12),
              SizedBox(height: 12),
              HomeSkeleton(width: 160, height: 36),
              SizedBox(height: 8),
              HomeSkeleton(width: 120, height: 16),
              SizedBox(height: 8),
              HomeSkeleton(width: 140, height: 14),
              SizedBox(height: 18),
              HomeSkeleton(width: double.infinity, height: 44, radius: 12),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        children: [
                          HomeSkeleton(width: 36, height: 26),
                          SizedBox(height: 8),
                          HomeSkeleton(width: 56, height: 12),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),
              const HomeSkeleton(width: 110, height: 14),
              const SizedBox(height: 14),
              const HomeSkeleton(width: double.infinity, height: 100),
              const SizedBox(height: 12),
              const HomeSkeleton(width: 200, height: 12),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Align(
          alignment: Alignment.centerLeft,
          child: HomeSkeleton(width: 90, height: 14),
        ),
        const SizedBox(height: 8),
        PremiumCard(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                const Row(
                  children: [
                    HomeSkeleton(width: 40, height: 12),
                    SizedBox(width: 12),
                    Expanded(
                      child: HomeSkeleton(
                        width: double.infinity,
                        height: 48,
                        radius: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
