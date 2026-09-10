import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Liste d’heures de prise éditables.
class MedTimesEditor extends StatelessWidget {
  const MedTimesEditor({
    super.key,
    required this.times,
    required this.onChanged,
  });

  final List<TimeOfDay> times;
  final ValueChanged<List<TimeOfDay>> onChanged;

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pick(BuildContext context, {TimeOfDay? existing, int? index}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: existing ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked == null) return;
    final next = List<TimeOfDay>.from(times);
    if (index != null) {
      next[index] = picked;
    } else if (!next.any((t) => t.hour == picked.hour && t.minute == picked.minute)) {
      next.add(picked);
      next.sort((a, b) => a.hour * 60 + a.minute - (b.hour * 60 + b.minute));
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < times.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: tokens.elevated,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _pick(context, existing: times[i], index: i);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tokens.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        IconsaxPlusLinear.clock,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _fmt(times[i]),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      if (times.length > 1)
                        IconButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            final next = List<TimeOfDay>.from(times)..removeAt(i);
                            onChanged(next);
                          },
                          icon: Icon(
                            IconsaxPlusLinear.trash,
                            size: 18,
                            color: tokens.textSecondary,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () {
            HapticFeedback.selectionClick();
            _pick(context);
          },
          icon: const Icon(IconsaxPlusLinear.add, size: 18),
          label: Text(l10n.medsAddTime),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      ],
    );
  }
}
