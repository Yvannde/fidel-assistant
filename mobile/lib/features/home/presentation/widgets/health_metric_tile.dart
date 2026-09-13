import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/constante_models.dart';
import 'constante_card.dart';

/// Carte indicateur pour la grille Santé — dimensions fixes.
class HealthMetricTile extends StatelessWidget {
  const HealthMetricTile({
    super.key,
    required this.type,
    required this.series,
    required this.recommended,
    required this.onTap,
  });

  final ConstanteType type;
  final ConstanteSeries? series;
  final bool recommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final hasData = series != null && series!.points.isNotEmpty;
    final latest = hasData ? series!.latest : null;

    return Material(
        color: tokens.isDark ? tokens.elevated : Colors.white,
        borderRadius: BorderRadius.circular(Premium.radiusSm),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(Premium.radiusSm),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Premium.radiusSm),
              border: Border.all(
                color: recommended
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : tokens.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      constanteIcon(type),
                      size: 15,
                      color:
                          recommended ? AppColors.primary : tokens.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        constanteLabel(l10n, type),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                    if (recommended)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l10n.healthRecommendedBadge,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (hasData)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          constanteValueText(context, latest!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.35,
                            height: 1.1,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _relativeDate(l10n, latest.mesureAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    l10n.healthNoData,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      color: tokens.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
    );
  }

  static String _relativeDate(AppLocalizations l10n, DateTime at) {
    final days = DateTime.now().difference(at).inDays;
    if (days <= 0) {
      return DateFormat.Hm().format(at);
    }
    return l10n.healthDaysAgo(days);
  }
}
