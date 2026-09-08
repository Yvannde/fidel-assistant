import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/constante_models.dart';
import 'constante_card.dart';
import 'home_skeleton.dart';

/// Résumé du jour — jusqu’à 3 dernières constantes
/// (`GET /patients/me/constantes`). Aucune valeur inventée.
class TodaySummaryCard extends StatelessWidget {
  const TodaySummaryCard({
    super.key,
    required this.series,
    required this.known,
    required this.onAdd,
    required this.onViewAll,
    this.subtitle,
  });

  final List<ConstanteSeries> series;
  final bool known;
  final VoidCallback onAdd;
  final VoidCallback onViewAll;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);

    if (!known) {
      return PremiumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomeSkeleton(width: 140, height: 14),
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
      );
    }

    final tiles = series.take(3).toList();

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.homeTodaySummaryTitle,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onViewAll();
                },
                borderRadius: BorderRadius.circular(Premium.radiusSm),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.homeTodaySummaryViewAll,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        IconsaxPlusLinear.arrow_right_3,
                        size: 12,
                        color: tokens.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle ??
                (tiles.isEmpty
                    ? l10n.homeTodaySummaryEmpty
                    : l10n.homeTodaySummaryBody),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12.5,
              height: 1.35,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          if (tiles.isEmpty)
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onAdd();
              },
              borderRadius: BorderRadius.circular(Premium.radiusSm),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Premium.radiusSm),
                  border: Border.all(color: tokens.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      IconsaxPlusLinear.add,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.homeVitalsEmptyTitle,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _VitalTile(series: tiles[i])),
                ],
                // Remplir la rangée si moins de 3 pour garder l’alignement.
                for (var i = tiles.length; i < 3; i++) ...[
                  const SizedBox(width: 8),
                  const Expanded(child: SizedBox()),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _VitalTile extends StatelessWidget {
  const _VitalTile({required this.series});

  final ConstanteSeries series;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final latest = series.latest;
    final accent = _accent(series.type);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Premium.radiusSm),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(constanteIcon(series.type), size: 18, color: accent),
          const SizedBox(height: 8),
          Text(
            constanteLabel(l10n, series.type),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              constanteValueText(context, latest),
              maxLines: 1,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.1,
                color: tokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _accent(ConstanteType type) {
    return switch (type) {
      ConstanteType.tension || ConstanteType.glycemie => const Color(0xFFDC2626),
      ConstanteType.sommeil => const Color(0xFFD97706),
      ConstanteType.poids || ConstanteType.temperature => AppColors.primary,
      ConstanteType.humeur => const Color(0xFF16A34A),
    };
  }
}
