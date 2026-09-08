import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Jours de prise — `tous` ou liste FR (`lundi`…`dimanche`).
class MedDaysSelector extends StatelessWidget {
  const MedDaysSelector({
    super.key,
    required this.everyDay,
    required this.selectedDays,
    required this.onEveryDayChanged,
    required this.onDaysChanged,
  });

  final bool everyDay;
  final Set<String> selectedDays;
  final ValueChanged<bool> onEveryDayChanged;
  final ValueChanged<Set<String>> onDaysChanged;

  static const weekdays = [
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final theme = Theme.of(context);

    String short(String d) => switch (d) {
          'lundi' => l10n.medsDayMon,
          'mardi' => l10n.medsDayTue,
          'mercredi' => l10n.medsDayWed,
          'jeudi' => l10n.medsDayThu,
          'vendredi' => l10n.medsDayFri,
          'samedi' => l10n.medsDaySat,
          _ => l10n.medsDaySun,
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: everyDay
              ? AppColors.primary.withValues(alpha: tokens.isDark ? 0.2 : 0.07)
              : tokens.elevated,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onEveryDayChanged(true);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: everyDay ? AppColors.primary : tokens.border,
                  width: everyDay ? 1.8 : 1.1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.medsDaysEvery,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    everyDay
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: everyDay ? AppColors.primary : tokens.divider,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: !everyDay
              ? AppColors.primary.withValues(alpha: tokens.isDark ? 0.2 : 0.07)
              : tokens.elevated,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onEveryDayChanged(false);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: !everyDay ? AppColors.primary : tokens.border,
                  width: !everyDay ? 1.8 : 1.1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.medsDaysCustom,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        !everyDay
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: !everyDay ? AppColors.primary : tokens.divider,
                      ),
                    ],
                  ),
                  if (!everyDay) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final d in weekdays)
                          FilterChip(
                            label: Text(short(d)),
                            selected: selectedDays.contains(d),
                            onSelected: (sel) {
                              HapticFeedback.selectionClick();
                              final next = Set<String>.from(selectedDays);
                              if (sel) {
                                next.add(d);
                              } else {
                                next.remove(d);
                              }
                              onDaysChanged(next);
                            },
                            selectedColor:
                                AppColors.primary.withValues(alpha: 0.16),
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: selectedDays.contains(d)
                                  ? AppColors.primary
                                  : tokens.textPrimary,
                            ),
                            side: BorderSide(
                              color: selectedDays.contains(d)
                                  ? AppColors.primary
                                  : tokens.border,
                            ),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
