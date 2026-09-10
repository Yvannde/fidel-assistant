import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/dashboard_models.dart';

/// Cartes style référence : icône + libellé + « X sur Y », ombre douce.
class CareProgressCards extends StatelessWidget {
  const CareProgressCards({
    super.key,
    required this.taken,
    required this.total,
    required this.late,
    required this.checkIn,
  });

  final int taken;
  final int total;
  final int late;
  final CheckInEntry? checkIn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);

    final checkValue = checkIn == null
        ? l10n.homeCareProgressCheckInTodo
        : (checkIn!.isOk
            ? l10n.homeCareProgressCheckInOk
            : l10n.homeCareProgressCheckInBad);

    return Row(
      children: [
        Expanded(
          child: _SoftCard(
            icon: IconsaxPlusLinear.health,
            label: l10n.homeCareProgressPrises,
            value: total == 0
                ? '—'
                : l10n.homeCareOfValue(taken, total),
            tokens: tokens,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SoftCard(
            icon: IconsaxPlusLinear.clock,
            label: l10n.homeCareProgressLate,
            value: '$late',
            tokens: tokens,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SoftCard(
            icon: IconsaxPlusLinear.heart,
            label: l10n.homeCareProgressCheckIn,
            value: checkValue,
            tokens: tokens,
          ),
        ),
      ],
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.tokens,
  });

  final IconData icon;
  final String label;
  final String value;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: tokens.isDark ? tokens.elevated : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: tokens.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: const Color(0xFF8B7FA8)),
          const SizedBox(height: 12),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: tokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
