import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/dashboard_models.dart';
import 'day_ring.dart';
import 'home_skeleton.dart';

/// Progression du jour — prises confirmées / prévues.
/// Ce n’est **pas** un score de santé : uniquement l’observance du jour
/// (données `prises_aujourdhui` / `GET /patients/me/prises`).
class DayProgressCard extends StatelessWidget {
  const DayProgressCard({
    super.key,
    required this.dashboard,
    required this.now,
    this.loading = false,
  });

  final PatientDashboard? dashboard;
  final DateTime now;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);

    if (loading) {
      return PremiumCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  HomeSkeleton(width: 120, height: 12),
                  SizedBox(height: 14),
                  HomeSkeleton(width: 88, height: 36),
                  SizedBox(height: 10),
                  HomeSkeleton(width: 64, height: 14),
                ],
              ),
            ),
            const HomeSkeleton(width: 72, height: 72, radius: 36),
          ],
        ),
      );
    }

    final prises = dashboard?.prisesAujourdhui ?? const <PriseDuJour>[];
    final done = dashboard?.takenCount() ?? 0;
    final total = prises.length;
    final late = dashboard?.lateCount(now) ?? 0;
    final pending = dashboard?.pendingCount(now) ?? 0;

    final status = _status(l10n, done: done, total: total, late: late);
    final statusColor = total > 0 && done == total
        ? AppColors.success
        : late > 0
            ? AppColors.warning
            : AppColors.primary;

    return PremiumCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.homeDayProgressTitle,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                    Tooltip(
                      message: l10n.homeDayProgressHint,
                      child: Icon(
                        IconsaxPlusLinear.info_circle,
                        size: 16,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (total == 0)
                  Text(
                    l10n.homeNoDoses,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14,
                      height: 1.35,
                      color: tokens.textSecondary,
                    ),
                  )
                else ...[
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$done',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            height: 1,
                            letterSpacing: -1.4,
                            color: tokens.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: ' / $total',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    status,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                  if (pending > 0 || late > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      _detail(l10n, pending: pending, late: late),
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          if (total > 0) ...[
            const SizedBox(width: 12),
            DayRing(
              done: done,
              total: total,
              trackColor: tokens.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFEEF2F7),
              progressColor: statusColor,
              labelColor: tokens.textPrimary,
              size: 72,
              stroke: 7,
            ),
          ],
        ],
      ),
    );
  }

  static String _status(
    AppLocalizations l10n, {
    required int done,
    required int total,
    required int late,
  }) {
    if (total == 0) return '';
    if (done == total) return l10n.homeDayProgressDone;
    if (done == 0 && late == 0) return l10n.homeDayProgressUpcoming;
    if (late > 0) return l10n.homeDayProgressLate;
    return l10n.homeDayProgressOngoing;
  }

  static String _detail(
    AppLocalizations l10n, {
    required int pending,
    required int late,
  }) {
    final parts = <String>[];
    if (pending > 0) parts.add(l10n.homeDayProgressPendingCount(pending));
    if (late > 0) parts.add(l10n.homeDayProgressLateCount(late));
    return parts.join(' · ');
  }
}
