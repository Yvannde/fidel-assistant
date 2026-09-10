import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/constante_models.dart';
import '../../domain/dashboard_models.dart';
import 'care_trend_chart.dart';
import 'constante_card.dart';

/// Hero style référence : gros chiffre, fond soft, courbe pastel pleine largeur.
class CareHeroMetric extends StatefulWidget {
  const CareHeroMetric({
    super.key,
    required this.series,
    required this.prises,
    required this.taken,
    required this.totalPrises,
    required this.onAddVital,
    required this.onRefresh,
  });

  final List<ConstanteSeries> series;
  final List<PriseDuJour> prises;
  final int taken;
  final int totalPrises;
  final VoidCallback onAddVital;
  final VoidCallback onRefresh;

  @override
  State<CareHeroMetric> createState() => _CareHeroMetricState();
}

class _CareHeroMetricState extends State<CareHeroMetric> {
  ConstanteType? _selected;

  ConstanteSeries? get _current {
    if (widget.series.isEmpty) return null;
    for (final s in widget.series) {
      if (s.type == _selected) return s;
    }
    return widget.series.first;
  }

  List<CareChartPoint> _vitalPoints(ConstanteSeries series, String locale) {
    final fmt = DateFormat.jm(locale);
    return [
      for (final p in series.points)
        CareChartPoint(value: p.systolique, label: fmt.format(p.mesureAt)),
    ];
  }

  List<CareChartPoint> _dosePoints(String locale) {
    if (widget.prises.isEmpty) return const [];
    final sorted = [...widget.prises]
      ..sort((a, b) => a.heurePrevue.compareTo(b.heurePrevue));
    final fmt = DateFormat.jm(locale);
    var confirmed = 0;
    final out = <CareChartPoint>[];
    for (final p in sorted) {
      if (p.isTaken) confirmed++;
      out.add(
        CareChartPoint(
          value: confirmed.toDouble(),
          label: fmt.format(p.heurePrevue),
        ),
      );
    }
    if (confirmed == 0 && out.length >= 2) {
      return [
        for (var i = 0; i < sorted.length; i++)
          CareChartPoint(
            value: sorted[i].isMissed
                ? 0
                : (sorted[i].isLate(DateTime.now()) ? 0.35 : 0.7),
            label: fmt.format(sorted[i].heurePrevue),
          ),
      ];
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final locale = Localizations.localeOf(context).toString();
    final series = _current;
    final hasVitals = series != null && series.points.isNotEmpty;
    final chartPoints =
        hasVitals ? _vitalPoints(series, locale) : _dosePoints(locale);

    final softBg = tokens.isDark
        ? const Color(0xFF1A1824)
        : const Color(0xFFF3F1F6);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      decoration: BoxDecoration(
        color: softBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: hasVitals
                                    ? constanteValueText(
                                        context,
                                        series.latest,
                                        withUnit: false,
                                      )
                                    : '${widget.taken}',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                  letterSpacing: -1.6,
                                  color: tokens.textPrimary,
                                ),
                              ),
                              TextSpan(
                                text: hasVitals
                                    ? ' ${series.latest.unite}'
                                    : ' / ${widget.totalPrises}',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  height: 1,
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasVitals
                            ? constanteLabel(l10n, series.type)
                            : l10n.homeCareHeroDosesLabel,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    widget.onAddVital();
                  },
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    IconsaxPlusLinear.clock,
                    size: 22,
                    color: tokens.textSecondary,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    widget.onRefresh();
                  },
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    IconsaxPlusLinear.refresh,
                    size: 22,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
            if (widget.series.length > 1) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 28,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.series.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, i) {
                    final type = widget.series[i].type;
                    final selected = type == series!.type;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selected = type);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          constanteLabel(l10n, type),
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? tokens.textPrimary
                                : tokens.textSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (chartPoints.isNotEmpty)
              CareTrendChart(points: chartPoints)
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Text(
                  l10n.homeCareHeroNoVital,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    color: tokens.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
