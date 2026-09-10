import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/home_controller.dart';
import '../../domain/dashboard_models.dart';
import 'home_skeleton.dart';

/// 3 KPIs du jour + histogramme d’observance de la semaine.
/// Données : prises du jour + `state.week` (agrégat local).
class HomeKpisWeek extends StatelessWidget {
  const HomeKpisWeek({
    super.key,
    required this.pending,
    required this.taken,
    required this.late,
    required this.week,
    required this.weekLoading,
  });

  final int pending;
  final int taken;
  final int late;
  final List<DayAdherence> week;
  final bool weekLoading;

  static const double _barHeight = 80;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final locale = Localizations.localeOf(context).toString();
    final today = homeDateOnly(DateTime.now());

    final elapsed = week.where((d) => !d.day.isAfter(today)).toList();
    final confirmed = elapsed.fold<int>(0, (s, d) => s + d.confirmed);
    final planned = elapsed.fold<int>(0, (s, d) => s + d.total);
    final showWeekSkeleton = weekLoading &&
        elapsed.every((d) => homeSameDay(d.day, today) || !d.hasDoses);

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _KpiCell(
                  value: pending,
                  label: l10n.homeStatPending,
                  color: AppColors.primary,
                ),
              ),
              Container(width: 1, height: 44, color: tokens.border),
              Expanded(
                child: _KpiCell(
                  value: taken,
                  label: l10n.homeStatTaken,
                  color: AppColors.success,
                ),
              ),
              Container(width: 1, height: 44, color: tokens.border),
              Expanded(
                child: _KpiCell(
                  value: late,
                  label: l10n.homeStatLate,
                  color: late > 0 ? AppColors.warning : tokens.textSecondary,
                  emphasize: late > 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.homeWeekTitle,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              if (showWeekSkeleton)
                const HomeSkeleton(width: 14, height: 14, radius: 7),
            ],
          ),
          const SizedBox(height: 14),
          if (showWeekSkeleton)
            const HomeSkeleton(width: double.infinity, height: 100)
          else ...[
            SizedBox(
              height: _barHeight + 24,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final day in week)
                    Expanded(
                      child: _WeekBar(
                        data: day,
                        isToday: homeSameDay(day.day, today),
                        isFuture: day.day.isAfter(today),
                        letter: _letter(locale, day.day),
                        tokens: tokens,
                        height: _barHeight,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              planned == 0
                  ? l10n.homeWeekEmpty
                  : l10n.homeWeekSummary(confirmed, planned),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: tokens.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _letter(String locale, DateTime day) {
    final raw = DateFormat.E(locale).format(day).trim();
    if (raw.isEmpty) return '';
    return raw[0].toUpperCase();
  }
}

class _KpiCell extends StatelessWidget {
  const _KpiCell({
    required this.value,
    required this.label,
    required this.color,
    this.emphasize = false,
  });

  final int value;
  final String label;
  final Color color;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Column(
      children: [
        _AnimatedInt(
          value: value,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            height: 1,
            letterSpacing: -0.8,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: tokens.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: emphasize ? 16 : 0,
          height: 2,
          decoration: BoxDecoration(
            color: emphasize ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}

class _AnimatedInt extends StatefulWidget {
  const _AnimatedInt({required this.value, required this.style});

  final int value;
  final TextStyle style;

  @override
  State<_AnimatedInt> createState() => _AnimatedIntState();
}

class _AnimatedIntState extends State<_AnimatedInt> {
  late int _from;

  @override
  void initState() {
    super.initState();
    _from = 0;
  }

  @override
  void didUpdateWidget(covariant _AnimatedInt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _from = oldWidget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      key: ValueKey('${_from}_${widget.value}'),
      tween: IntTween(begin: _from, end: widget.value),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Text('$value', style: widget.style);
      },
    );
  }
}

class _WeekBar extends StatelessWidget {
  const _WeekBar({
    required this.data,
    required this.isToday,
    required this.isFuture,
    required this.letter,
    required this.tokens,
    required this.height,
  });

  final DayAdherence data;
  final bool isToday;
  final bool isFuture;
  final String letter;
  final ThemeTokens tokens;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ratio = data.ratio ?? 0.0;
    final complete = data.isComplete;
    final fill = complete ? AppColors.success : AppColors.primary;
    final track = tokens.isDark
        ? Colors.white.withValues(alpha: 0.07)
        : const Color(0xFFEEF2F7);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: height,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: 18,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: isFuture ? track.withValues(alpha: 0.45) : track,
                      borderRadius: BorderRadius.circular(4),
                      border: isToday
                          ? Border.all(
                              color: AppColors.primary.withValues(alpha: 0.35),
                            )
                          : null,
                    ),
                  ),
                  if (!isFuture && ratio > 0)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0)),
                      duration: const Duration(milliseconds: 650),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Container(
                          height: (height * value).clamp(8.0, height),
                          decoration: BoxDecoration(
                            color: fill,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          letter,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 12,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            color: isToday
                ? AppColors.primary
                : tokens.textSecondary.withValues(alpha: isFuture ? 0.45 : 1),
          ),
        ),
      ],
    );
  }
}
