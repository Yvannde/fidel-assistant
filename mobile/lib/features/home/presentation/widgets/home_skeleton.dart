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

/// Hub Profil — header + 3 sections de réglages.
class HomeProfileSkeleton extends StatelessWidget {
  const HomeProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumCard(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Row(
            children: const [
              HomeSkeleton(width: 56, height: 56, radius: 28),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeSkeleton(width: 140, height: 18),
                    SizedBox(height: 8),
                    HomeSkeleton(width: 180, height: 12),
                    SizedBox(height: 10),
                    HomeSkeleton(width: 90, height: 22, radius: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        for (var s = 0; s < 3; s++) ...[
          if (s > 0) const SizedBox(height: 18),
          const HomeSkeleton(width: 100, height: 12),
          const SizedBox(height: 8),
          PremiumCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < 2; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 48),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    child: Row(
                      children: [
                        HomeSkeleton(width: 22, height: 22, radius: 6),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              HomeSkeleton(width: 120, height: 14),
                              SizedBox(height: 6),
                              HomeSkeleton(width: 160, height: 11),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Sous-écran réglages — titre implicite + carte de lignes.
class ProfilePageSkeleton extends StatelessWidget {
  const ProfilePageSkeleton({super.key, this.rows = 4});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const HomeSkeleton(width: 240, height: 14),
        const SizedBox(height: 16),
        PremiumCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < rows; i++) ...[
                if (i > 0) const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HomeSkeleton(width: 140, height: 14),
                            SizedBox(height: 8),
                            HomeSkeleton(width: 200, height: 11),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      HomeSkeleton(width: 40, height: 24, radius: 12),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Liste (aidants, contacts) — cartes empilées (Column, pas de ListView imbriqué).
class ProfileListSkeleton extends StatelessWidget {
  const ProfileListSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          PremiumCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Row(
              children: const [
                HomeSkeleton(width: 40, height: 40, radius: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HomeSkeleton(width: 120, height: 14),
                      SizedBox(height: 8),
                      HomeSkeleton(width: 160, height: 11),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Onglet Soins — hero + cartes.
class HomeCareSkeleton extends StatelessWidget {
  const HomeCareSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HomeSkeleton(width: 100, height: 28),
        const SizedBox(height: 8),
        const HomeSkeleton(width: 200, height: 14),
        const SizedBox(height: 18),
        const Row(
          children: [
            Expanded(child: HomeSkeleton(width: double.infinity, height: 40, radius: 12)),
            SizedBox(width: 8),
            Expanded(child: HomeSkeleton(width: double.infinity, height: 40, radius: 12)),
            SizedBox(width: 8),
            Expanded(child: HomeSkeleton(width: double.infinity, height: 40, radius: 12)),
          ],
        ),
        const SizedBox(height: 18),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              HomeSkeleton(width: 80, height: 12),
              SizedBox(height: 12),
              HomeSkeleton(width: 100, height: 36),
              SizedBox(height: 16),
              HomeSkeleton(width: double.infinity, height: 120, radius: 12),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Row(
          children: [
            Expanded(child: HomeSkeleton(width: double.infinity, height: 72, radius: 12)),
            SizedBox(width: 10),
            Expanded(child: HomeSkeleton(width: double.infinity, height: 72, radius: 12)),
          ],
        ),
        const SizedBox(height: 22),
        const HomeSkeleton(width: 90, height: 14),
        const SizedBox(height: 10),
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          const HomeSkeleton(width: double.infinity, height: 56, radius: 12),
        ],
      ],
    );
  }
}
