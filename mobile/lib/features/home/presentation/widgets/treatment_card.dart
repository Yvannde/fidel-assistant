import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/dashboard_models.dart';

/// Bloc traitement — contenu pour le panneau Suivi (pas de badge gradient).
class TreatmentBlock extends StatelessWidget {
  const TreatmentBlock({
    super.key,
    required this.traitement,
    required this.detail,
    this.onTap,
    this.onTerminate,
  });

  final DashboardTraitement traitement;
  final TraitementDetail? detail;
  final VoidCallback? onTap;
  final VoidCallback? onTerminate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);

    final day = traitement.jourTraitement ?? detail?.jourTraitement;
    final total = detail?.dureeTotale;
    final phase = _phaseLabel(l10n, traitement.phase);
    final progress = (day != null && total != null && total > 0)
        ? (day / total).clamp(0.0, 1.0)
        : null;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                traitement.maladieNom,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (phase != null)
              Text(
                phase,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tokens.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (progress != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: tokens.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFEEF2F7),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.homeTreatmentDayOf(day!, total!),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tokens.textSecondary,
            ),
          ),
        ] else
          Text(
            day == null
                ? l10n.homeTreatmentOngoing
                : l10n.homeTreatmentDay(day),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tokens.textSecondary,
            ),
          ),
        if (onTerminate != null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                onTerminate!();
              },
              style: TextButton.styleFrom(
                foregroundColor: tokens.textSecondary,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.homeTreatmentEndAction,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );

    if (onTap == null) return body;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Premium.radiusSm),
      child: body,
    );
  }

  static String? _phaseLabel(AppLocalizations l10n, String phase) {
    return switch (phase) {
      'debut' => l10n.homePhaseDebut,
      'en_cours' => l10n.homePhaseEnCours,
      'maintenance' => l10n.homePhaseMaintenance,
      _ => null,
    };
  }
}

/// Conservé pour l’onglet Soins éventuel — wrapper mince.
class TreatmentCard extends StatelessWidget {
  const TreatmentCard({
    super.key,
    required this.traitement,
    required this.detail,
    this.onTap,
    this.onTerminate,
  });

  final DashboardTraitement traitement;
  final TraitementDetail? detail;
  final VoidCallback? onTap;
  final VoidCallback? onTerminate;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: TreatmentBlock(
        traitement: traitement,
        detail: detail,
        onTap: onTap,
        onTerminate: onTerminate,
      ),
    );
  }
}
