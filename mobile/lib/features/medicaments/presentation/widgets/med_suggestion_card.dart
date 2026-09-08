import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../home/domain/dashboard_models.dart';

/// Carte suggestion protocole — sélectionne nom / dosage / forme / horaires.
class MedSuggestionCard extends StatelessWidget {
  const MedSuggestionCard({
    super.key,
    required this.suggestion,
    required this.selected,
    required this.onTap,
  });

  final DoseSuggestion suggestion;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(14);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: tokens.isDark ? 0.22 : 0.08)
            : tokens.elevated,
        borderRadius: radius,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: radius,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected ? AppColors.primary : tokens.border,
                width: selected ? 1.8 : 1.1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.nom,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          suggestion.dosage,
                          if (suggestion.forme.isNotEmpty) suggestion.forme,
                          if (suggestion.horaires.isNotEmpty)
                            suggestion.horaires.join(' · '),
                        ].where((e) => e.isNotEmpty).join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: selected ? AppColors.primary : tokens.divider,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
