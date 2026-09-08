import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Sélecteur de forme galénique (valeurs API libres).
class MedFormeSelector extends StatelessWidget {
  const MedFormeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  static const values = ['comprime', 'sirop', 'injection', 'autre'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);

    String label(String v) => switch (v) {
          'comprime' => l10n.medsFormeComprime,
          'sirop' => l10n.medsFormeSirop,
          'injection' => l10n.medsFormeInjection,
          _ => l10n.medsFormeAutre,
        };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          ChoiceChip(
            label: Text(label(v)),
            selected: value == v,
            onSelected: (_) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
            selectedColor: AppColors.primary.withValues(alpha: 0.16),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: value == v ? AppColors.primary : tokens.textPrimary,
            ),
            side: BorderSide(
              color: value == v ? AppColors.primary : tokens.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
      ],
    );
  }
}
