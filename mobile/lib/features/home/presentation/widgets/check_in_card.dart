import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/dashboard_models.dart';

/// Ligne de check-in — destinée à vivre *dans* le panneau Aujourd’hui.
/// Pas de carte autonome, pas d’emoji.
class CheckInRow extends StatelessWidget {
  const CheckInRow({
    super.key,
    required this.answer,
    required this.busy,
    required this.onAnswer,
  });

  final CheckInEntry? answer;
  final bool busy;
  final ValueChanged<String> onAnswer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);

    if (answer != null) {
      return Row(
        children: [
          Icon(
            answer!.isOk
                ? IconsaxPlusLinear.like
                : IconsaxPlusLinear.dislike,
            size: 18,
            color: tokens.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              answer!.isOk ? l10n.homeCheckInDoneOk : l10n.homeCheckInDoneBad,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
          ),
          Icon(
            IconsaxPlusLinear.tick_circle,
            size: 18,
            color: AppColors.success,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.homeCheckInTitle,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: tokens.textPrimary,
            ),
          ),
        ),
        _Choice(
          icon: IconsaxPlusLinear.like,
          label: l10n.homeCheckInOk,
          onTap: busy ? null : () => onAnswer('ca_va'),
        ),
        const SizedBox(width: 6),
        _Choice(
          icon: IconsaxPlusLinear.dislike,
          label: l10n.homeCheckInBad,
          onTap: busy ? null : () => onAnswer('pas_top'),
        ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final radius = BorderRadius.circular(Premium.radiusSm);
    return Material(
      color: tokens.isDark
          ? Colors.white.withValues(alpha: 0.06)
          : const Color(0xFFF1F5F9),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: tokens.textPrimary),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
