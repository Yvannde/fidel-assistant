import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/constante_models.dart';
import 'sparkline.dart';

String constanteLabel(AppLocalizations l10n, ConstanteType type) {
  return switch (type) {
    ConstanteType.poids => l10n.constantePoids,
    ConstanteType.tension => l10n.constanteTension,
    ConstanteType.glycemie => l10n.constanteGlycemie,
    ConstanteType.temperature => l10n.constanteTemperature,
    ConstanteType.sommeil => l10n.constanteSommeil,
    ConstanteType.humeur => l10n.constanteHumeur,
  };
}

IconData constanteIcon(ConstanteType type) {
  return switch (type) {
    ConstanteType.poids => IconsaxPlusLinear.weight,
    ConstanteType.tension => IconsaxPlusLinear.drop,
    ConstanteType.glycemie => IconsaxPlusLinear.activity,
    ConstanteType.temperature => IconsaxPlusLinear.status,
    ConstanteType.sommeil => IconsaxPlusLinear.moon,
    ConstanteType.humeur => IconsaxPlusLinear.like_1,
  };
}

String constanteValueText(
  BuildContext context,
  Constante measure, {
  bool withUnit = true,
}) {
  final locale = Localizations.localeOf(context).toString();
  final format = NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: measure.type.decimals,
  );
  final body = measure.type.isPaired
      ? '${measure.systolique.round()}/${measure.diastolique?.round() ?? 0}'
      : format.format(measure.systolique);
  return withUnit ? '$body ${measure.unite}' : body;
}

/// Bloc constantes pour le panneau Suivi — sans carte autonome.
class ConstanteBlock extends StatefulWidget {
  const ConstanteBlock({
    super.key,
    required this.series,
    required this.onAdd,
  });

  final List<ConstanteSeries> series;
  final VoidCallback onAdd;

  @override
  State<ConstanteBlock> createState() => _ConstanteBlockState();
}

class _ConstanteBlockState extends State<ConstanteBlock> {
  ConstanteType? _selected;

  ConstanteSeries get _current {
    for (final s in widget.series) {
      if (s.type == _selected) return s;
    }
    return widget.series.first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final locale = Localizations.localeOf(context).toString();
    final series = _current;
    final latest = series.latest;
    final delta = series.delta;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              constanteIcon(series.type),
              size: 16,
              color: tokens.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                constanteLabel(l10n, series.type),
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
              ),
            ),
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onAdd();
              },
              borderRadius: BorderRadius.circular(Premium.radiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(IconsaxPlusLinear.add, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      l10n.homeVitalsAdd,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (widget.series.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 28,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.series.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final type = widget.series[i].type;
                final selected = type == series.type;
                return Material(
                  color: selected
                      ? AppColors.primary
                      : (tokens.isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(Premium.radiusSm),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Premium.radiusSm),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selected = type);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Center(
                        child: Text(
                          constanteLabel(l10n, type),
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : tokens.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  constanteValueText(context, latest),
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    letterSpacing: -0.8,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
            ),
            if (delta != null) ...[
              const SizedBox(width: 8),
              Text(
                _deltaText(context, delta, series.type, latest.unite),
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tokens.textSecondary,
                ),
              ),
            ],
          ],
        ),
        if (series.points.length >= 2) ...[
          const SizedBox(height: 12),
          Sparkline(
            values: [for (final p in series.points) p.systolique],
            secondary: series.type.isPaired
                ? [for (final p in series.points) p.diastolique ?? 0]
                : null,
            color: AppColors.primary,
            secondaryColor: AppColors.primary.withValues(alpha: 0.35),
            surface: tokens.isDark ? tokens.elevated : Colors.white,
            height: 72,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                DateFormat.MMMd(locale).format(series.points.first.mesureAt),
                style: _axis(tokens),
              ),
              const Spacer(),
              Text(
                DateFormat.MMMd(locale).format(latest.mesureAt),
                style: _axis(tokens),
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            l10n.homeVitalsFirst,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              height: 1.35,
              color: tokens.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  static String _deltaText(
    BuildContext context,
    double delta,
    ConstanteType type,
    String unit,
  ) {
    final locale = Localizations.localeOf(context).toString();
    final format = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: type.decimals,
    );
    final up = delta > 0;
    return '${up ? '+' : '−'}${format.format(delta.abs())} $unit';
  }

  static TextStyle _axis(ThemeTokens tokens) => TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: tokens.textSecondary,
      );
}

/// Lien « Ajouter une mesure » quand aucune constante n’existe.
class ConstanteAddLink extends StatelessWidget {
  const ConstanteAddLink({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onAdd();
      },
      borderRadius: BorderRadius.circular(Premium.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(IconsaxPlusLinear.add, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.homeVitalsEmptyTitle,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
            ),
            Icon(
              IconsaxPlusLinear.arrow_right_3,
              size: 16,
              color: tokens.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Ancien wrapper carte — encore utilisé éventuellement hors panneau.
class ConstanteCard extends StatelessWidget {
  const ConstanteCard({
    super.key,
    required this.series,
    required this.onAdd,
  });

  final List<ConstanteSeries> series;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: ConstanteBlock(series: series, onAdd: onAdd),
    );
  }
}

class ConstanteEmptyCard extends StatelessWidget {
  const ConstanteEmptyCard({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onAdd,
      child: ConstanteAddLink(onAdd: onAdd),
    );
  }
}
