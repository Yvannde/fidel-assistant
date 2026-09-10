import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
import 'home_lottie.dart';

/// Empty state premium quand aucun aidant n’est encore lié.
class AidantsEmptyState extends StatelessWidget {
  const AidantsEmptyState({
    super.key,
    required this.onInvite,
  });

  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: tokens.isDark ? tokens.elevated : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
            clipBehavior: Clip.antiAlias,
            child: const Center(
              child: HomeLottie(
                asset: 'assets/lottie/welcome.json',
                size: 72,
                fallbackIcon: IconsaxPlusLinear.user_add,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.homeAidantsEmptyTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.homeAidantsEmptyBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              height: 1.4,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                onInvite();
              },
              icon: const Icon(IconsaxPlusLinear.user_add, size: 18),
              label: Text(
                l10n.homeAidantsInviteCta,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.45),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
