import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium.dart';
import '../../../l10n/app_localizations.dart';
import '../application/home_controller.dart';
import '../domain/dashboard_models.dart';
import 'widgets/add_constante_sheet.dart';
import 'widgets/care_activity_feed.dart';
import 'widgets/care_hero_metric.dart';
import 'widgets/care_progress_cards.dart';
import 'widgets/treatment_card.dart';

/// Onglet Soins — hub de suivi dense (hero, courbe, progression, journal).
class HomeCareScreen extends ConsumerWidget {
  const HomeCareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final state = ref.watch(homeControllerProvider);
    final dash = state.dashboard;
    final traitements = dash?.traitements ?? const <DashboardTraitement>[];
    final prises = dash?.prisesAujourdhui ?? const <PriseDuJour>[];
    final padTop = 12 + MediaQuery.paddingOf(context).top;
    final now = DateTime.now();

    final unconfigured = dash?.firstUnconfigured;
    final medsTargetId = unconfigured?.id ??
        (traitements.isNotEmpty ? traitements.first.id : null);
    final taken = dash?.takenCount() ?? 0;
    final late = dash?.lateCount(now) ?? 0;
    final totalPrises = prises.length;

    final feedItems = CareFeedItem.build(
      l10n: l10n,
      context: context,
      prises: prises,
      constantes: state.constantes,
      checkIn: state.todayCheckIn,
    );

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(homeControllerProvider.notifier).load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          Premium.screenPad,
          padTop,
          Premium.screenPad,
          Premium.navClearance,
        ),
        children: [
          Text(
            l10n.navCare,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.homeCareSubtitle,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 15,
              height: 1.4,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 18),

          if (!state.hasPatient)
            _CareEmptyCard(
              icon: IconsaxPlusLinear.health,
              title: l10n.homeCareEmptyPatientTitle,
              body: l10n.homeActivateBody,
              cta: l10n.navHome,
              onTap: () =>
                  ref.read(homeTabIndexProvider.notifier).state = 0,
            )
          else ...[
            _CareQuickActions(
              onTraitement: () => context.push('/home/traitement'),
              onMeds: medsTargetId == null
                  ? null
                  : () => context.push(
                        '/home/medicaments',
                        extra: medsTargetId,
                      ),
              onVital: () => AddConstanteSheet.show(context),
              medsNeedsConfig: unconfigured != null,
            ),
            const SizedBox(height: 18),

            if (traitements.isEmpty)
              _CareEmptyCard(
                icon: IconsaxPlusLinear.hospital,
                title: l10n.homeActionTraitementTitle,
                body: l10n.homeActionTraitementBody,
                cta: l10n.homeActionTraitementTitle,
                onTap: () => context.push('/home/traitement'),
              )
            else ...[
              if (unconfigured != null) ...[
                _CareEmptyCard(
                  icon: IconsaxPlusLinear.add_circle,
                  title: l10n.homeActionMedsTitle,
                  body: l10n.homeActionMedsFor(unconfigured.maladieNom),
                  cta: l10n.homeCareConfigureMeds,
                  onTap: () => context.push(
                    '/home/medicaments',
                    extra: unconfigured.id,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              CareHeroMetric(
                series: state.constantesKnown
                    ? state.constanteSeries
                    : const [],
                prises: prises,
                taken: taken,
                totalPrises: totalPrises,
                onAddVital: () => AddConstanteSheet.show(context),
                onRefresh: () =>
                    ref.read(homeControllerProvider.notifier).load(),
              ),
              const SizedBox(height: 14),
              CareProgressCards(
                taken: taken,
                total: totalPrises,
                late: late,
                checkIn: state.checkInKnown ? state.todayCheckIn : null,
              ),
              const SizedBox(height: 22),
              _CareSectionLabel(title: l10n.homeCareJournal),
              const SizedBox(height: 10),
              CareActivityFeed(
                items: feedItems,
                onAddVital: () => AddConstanteSheet.show(context),
                onPendingPriseTap: () =>
                    ref.read(homeTabIndexProvider.notifier).state = 0,
              ),
              const SizedBox(height: 22),
              _CareSectionLabel(title: l10n.homeCareTreatments),
              const SizedBox(height: 8),
              PremiumCard(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < traitements.length; i++) ...[
                      if (i > 0) ...[
                        const SizedBox(height: 12),
                        Divider(height: 1, color: tokens.border),
                        const SizedBox(height: 12),
                      ],
                      TreatmentBlock(
                        traitement: traitements[i],
                        detail: state.traitementDetails[traitements[i].id],
                      ),
                      const SizedBox(height: 10),
                      _CareInlineCta(
                        label: traitements[i].medicamentsConfigures
                            ? l10n.homeCareAddMed
                            : l10n.homeCareConfigureMeds,
                        onTap: () => context.push(
                          '/home/medicaments',
                          extra: traitements[i].id,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CareSectionLabel extends StatelessWidget {
  const _CareSectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Text(
      title,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: tokens.textSecondary,
      ),
    );
  }
}

class _CareQuickActions extends StatelessWidget {
  const _CareQuickActions({
    required this.onTraitement,
    required this.onMeds,
    required this.onVital,
    required this.medsNeedsConfig,
  });

  final VoidCallback onTraitement;
  final VoidCallback? onMeds;
  final VoidCallback onVital;
  final bool medsNeedsConfig;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _QuickActionChip(
            icon: IconsaxPlusLinear.hospital,
            label: l10n.homeCareActionTraitement,
            onTap: onTraitement,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionChip(
            icon: IconsaxPlusLinear.health,
            label: medsNeedsConfig
                ? l10n.homeCareActionMedsSetup
                : l10n.homeCareActionMeds,
            onTap: onMeds,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionChip(
            icon: IconsaxPlusLinear.activity,
            label: l10n.homeCareActionVital,
            onTap: onVital,
          ),
        ),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
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
    final enabled = onTap != null;

    return Material(
      color: enabled
          ? AppColors.primary.withValues(alpha: tokens.isDark ? 0.16 : 0.07)
          : tokens.elevated,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: enabled ? AppColors.primary : tokens.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: enabled ? tokens.textPrimary : tokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CareEmptyCard extends StatelessWidget {
  const _CareEmptyCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.cta,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final String cta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final theme = Theme.of(context);

    return PremiumCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 28, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              height: 1.4,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              cta,
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CareInlineCta extends StatelessWidget {
  const _CareInlineCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
