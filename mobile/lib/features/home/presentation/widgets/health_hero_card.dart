import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/constante_models.dart';
import 'constante_card.dart';
import 'health_mini_sparkline.dart';

/// Hero gradient — dernière mesure ou empty state encourageant.
class HealthHeroCard extends StatelessWidget {
  const HealthHeroCard({
    super.key,
    required this.latest,
    required this.series,
    required this.onTap,
    required this.onAdd,
  });

  final Constante? latest;
  final ConstanteSeries? series;
  final VoidCallback? onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasData = latest != null && series != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasData
            ? () {
                HapticFeedback.selectionClick();
                onTap?.call();
              }
            : null,
        borderRadius: BorderRadius.circular(Premium.radius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Premium.radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: hasData
                  ? const [AppColors.primarySoft, AppColors.primaryDark]
                  : const [AppColors.success, AppColors.successDark],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
          child: hasData
              ? _dataBody(context, l10n, latest!, series!)
              : _emptyBody(context, l10n),
        ),
      ),
    );
  }

  Widget _dataBody(
    BuildContext context,
    AppLocalizations l10n,
    Constante latest,
    ConstanteSeries series,
  ) {
    final points = [for (final p in series.points) p.systolique];
    final hasChart = points.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                constanteLabel(l10n, latest.type).toUpperCase(),
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: Color(0xCCFFFFFF),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                constanteValueText(context, latest),
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  letterSpacing: -1.2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat.yMMMd(Localizations.localeOf(context).toString())
                    .add_Hm()
                    .format(latest.mesureAt),
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
        if (hasChart) ...[
          const SizedBox(width: 8),
          HealthMiniSparkline(
            values: points,
            secondary: latest.type.isPaired
                ? [for (final p in series.points) p.diastolique ?? 0]
                : null,
          ),
        ],
      ],
    );
  }

  Widget _emptyBody(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.healthEmptyHero,
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.25,
            letterSpacing: -0.3,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            onAdd();
          },
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.successDark,
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Premium.radiusSm),
            ),
          ),
          child: Text(
            l10n.healthAddCta,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
