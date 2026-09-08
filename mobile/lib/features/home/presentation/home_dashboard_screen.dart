import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/home_controller.dart';
import '../domain/dashboard_models.dart';
import 'widgets/add_constante_sheet.dart';
import 'widgets/check_in_card.dart';
import 'widgets/day_ring.dart';
import 'widgets/dose_timeline.dart';
import 'widgets/home_header.dart';
import 'widgets/home_kpis_week.dart';
import 'widgets/home_skeleton.dart';
import 'widgets/next_dose_card.dart';
import 'widgets/snooze_sheet.dart';
import 'widgets/today_summary_card.dart';
import 'widgets/treatment_card.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(homeControllerProvider.notifier).load(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              Premium.screenPad,
              10 + MediaQuery.paddingOf(context).top,
              Premium.screenPad,
              Premium.navClearance,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                HomeHeader(
                  name: state.profile?.headerName ?? '',
                  initial: state.profile?.initial ?? '',
                  loading: state.loading && state.profile == null,
                ),
                const SizedBox(height: 16),
                ..._body(context, ref, state, l10n, now),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    WidgetRef ref,
    HomeUiState state,
    AppLocalizations l10n,
    DateTime now,
  ) {
    if (state.loading && state.profile == null) {
      return const [HomeDashboardSkeleton()];
    }

    if (state.error != null && state.profile == null) {
      return [_ErrorCard(message: state.error!, l10n: l10n)];
    }

    if (!state.hasPatient) {
      return [_ActivateBanner(l10n: l10n)];
    }

    final dash = state.dashboardForDay;
    final prises = state.visiblePrises;
    final cta = _onboardingCta(context, state, l10n);
    final showCheckIn = state.isTodaySelected &&
        (state.needsCheckIn || state.todayCheckIn != null);
    final traitements = dash?.traitements ?? const <DashboardTraitement>[];
    final dashLoading = state.loading && state.dashboard == null;
    final nowKpis = DateTime.now();

    return [
      // 1. CTA setup puis hero action
      if (cta != null) ...[cta, const SizedBox(height: 16)],
      if (state.isTodaySelected)
        if (prises.isNotEmpty) ...[
          NextDoseCard(
            next: dash?.nextDose(now),
            done: dash?.takenCount() ?? 0,
            total: prises.length,
            busy: state.busy,
            onConfirm: () => _confirmNext(context, ref, dash, now, l10n),
            onSnooze: () => _snoozeNext(context, ref, dash, now, l10n),
          ),
          const SizedBox(height: 16),
        ] else if (cta == null && !dashLoading) ...[
          HomeQuietHero(
            title: l10n.homeAllClearTitle,
            body: l10n.homeAllClearBody,
          ),
          const SizedBox(height: 16),
        ]
      else ...[
        _DaySummaryCard(day: state.day, prises: prises, l10n: l10n),
        const SizedBox(height: 16),
      ],

      // 2. KPIs du jour + graphe semaine
      HomeKpisWeek(
        pending: dash?.pendingCount(nowKpis) ?? 0,
        taken: dash?.takenCount() ?? 0,
        late: dash?.lateCount(nowKpis) ?? 0,
        week: state.week,
        weekLoading: state.weekLoading,
      ),
      const SizedBox(height: 20),

      // 3. Timeline + check-in
      _SectionLabel(
        title: state.isTodaySelected
            ? l10n.homeTodayTitle
            : _prettyDate(context, state.day),
        trailing: _remainingLabel(l10n, prises),
      ),
      const SizedBox(height: 8),
      PremiumCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showCheckIn) ...[
              CheckInRow(
                answer: state.todayCheckIn,
                busy: state.checkInBusy,
                onAnswer: (statut) => _checkIn(context, ref, statut, l10n),
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: ThemeTokens.of(context).border),
              const SizedBox(height: 4),
            ],
            DoseTimeline(
              prises: prises,
              now: now,
              busy: state.busy,
              onConfirm: (prise) => _confirm(context, ref, prise.id, l10n),
            ),
          ],
        ),
      ),

      // 4. Traitement
      if (traitements.isNotEmpty) ...[
        const SizedBox(height: 20),
        _SectionLabel(title: l10n.navCare),
        const SizedBox(height: 8),
        PremiumCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < traitements.length; i++) ...[
                if (i > 0) ...[
                  const SizedBox(height: 12),
                  Divider(height: 1, color: ThemeTokens.of(context).border),
                  const SizedBox(height: 12),
                ],
                TreatmentBlock(
                  traitement: traitements[i],
                  detail: state.traitementDetails[traitements[i].id],
                  onTap: () =>
                      ref.read(homeTabIndexProvider.notifier).state = 1,
                ),
              ],
            ],
          ),
        ),
      ],

      // 5. Constantes — en bas, pas en résumé wellness
      if (state.isTodaySelected && state.constantesKnown) ...[
        const SizedBox(height: 20),
        _SectionLabel(title: l10n.homeVitalsTitle),
        const SizedBox(height: 8),
        TodaySummaryCard(
          series: state.constanteSeries,
          known: state.constantesKnown,
          onAdd: () => AddConstanteSheet.show(context),
          onViewAll: () =>
              ref.read(homeTabIndexProvider.notifier).state = 1,
          subtitle: _summarySubtitle(state, l10n),
        ),
      ] else if (state.isTodaySelected && !state.constantesKnown) ...[
        const SizedBox(height: 20),
        TodaySummaryCard(
          series: const [],
          known: false,
          onAdd: () => AddConstanteSheet.show(context),
          onViewAll: () {},
        ),
      ],
    ];
  }

  static String? _summarySubtitle(HomeUiState state, AppLocalizations l10n) {
    final checkIn = state.todayCheckIn;
    if (checkIn != null) {
      return checkIn.isOk ? l10n.homeCheckInDoneOk : l10n.homeCheckInDoneBad;
    }
    return null;
  }

  Widget? _onboardingCta(
    BuildContext context,
    HomeUiState state,
    AppLocalizations l10n,
  ) {
    final dash = state.dashboard;
    if (dash == null || !state.isTodaySelected) return null;

    if (dash.prochaineAction == 'activer_notifications') {
      return _CtaBanner(
        icon: IconsaxPlusLinear.notification,
        title: l10n.homeActionNotifTitle,
        subtitle: l10n.homeActionNotifBody,
        onTap: () => context.push('/home/notifications'),
      );
    }
    if (dash.traitements.isEmpty) {
      return _CtaBanner(
        icon: IconsaxPlusLinear.health,
        title: l10n.homeActionTraitementTitle,
        subtitle: l10n.homeActionTraitementBody,
        onTap: () => context.push('/home/traitement'),
      );
    }
    final unconfigured = dash.firstUnconfigured;
    if (unconfigured != null) {
      return _CtaBanner(
        icon: IconsaxPlusLinear.hospital,
        title: l10n.homeActionMedsTitle,
        subtitle: l10n.homeActionMedsFor(unconfigured.maladieNom),
        onTap: () => context.push('/home/medicaments', extra: unconfigured.id),
      );
    }
    return null;
  }

  static String? _remainingLabel(
    AppLocalizations l10n,
    List<PriseDuJour> prises,
  ) {
    final remaining = prises.where((p) => !p.isTaken).length;
    if (prises.isEmpty || remaining == 0) return null;
    return l10n.homeRemaining(remaining);
  }

  static String _prettyDate(BuildContext context, DateTime day) {
    final locale = Localizations.localeOf(context).toString();
    final raw = DateFormat.MMMMEEEEd(locale).format(day);
    return raw.isEmpty ? raw : raw[0].toUpperCase() + raw.substring(1);
  }

  Future<void> _confirmNext(
    BuildContext context,
    WidgetRef ref,
    PatientDashboard? dash,
    DateTime now,
    AppLocalizations l10n,
  ) async {
    final next = dash?.nextDose(now);
    if (next == null) return;
    await _confirm(context, ref, next.id, l10n);
  }

  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref,
    String priseId,
    AppLocalizations l10n,
  ) async {
    try {
      await ref.read(homeControllerProvider.notifier).confirmPrise(priseId);
      if (context.mounted) AppToast.success(context, l10n.homeTakenToast);
    } catch (e) {
      if (context.mounted) {
        AppToast.error(
          context,
          e is ApiException ? e.message : l10n.genericError,
        );
      }
    }
  }

  Future<void> _snoozeNext(
    BuildContext context,
    WidgetRef ref,
    PatientDashboard? dash,
    DateTime now,
    AppLocalizations l10n,
  ) async {
    final next = dash?.nextDose(now);
    if (next == null) return;

    final delay = await SnoozeSheet.show(context, next.medicamentNom);
    if (delay == null || !context.mounted) return;

    final target = DateTime.now().add(delay);
    try {
      await ref
          .read(homeControllerProvider.notifier)
          .reportPrise(next.id, target);
      if (context.mounted) {
        AppToast.success(
          context,
          l10n.homeSnoozeDone(DateFormat.Hm().format(target)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(
          context,
          e is ApiException ? e.message : l10n.genericError,
        );
      }
    }
  }

  Future<void> _checkIn(
    BuildContext context,
    WidgetRef ref,
    String statut,
    AppLocalizations l10n,
  ) async {
    try {
      await ref.read(homeControllerProvider.notifier).submitCheckIn(statut);
    } catch (e) {
      if (context.mounted) {
        AppToast.error(
          context,
          e is ApiException ? e.message : l10n.genericError,
        );
      }
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: tokens.textSecondary,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }
}

class _CtaBanner extends StatelessWidget {
  const _CtaBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Material(
      color: AppColors.primary.withValues(alpha: tokens.isDark ? 0.14 : 0.06),
      borderRadius: BorderRadius.circular(Premium.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(Premium.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        height: 1.3,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                IconsaxPlusLinear.arrow_right_3,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaySummaryCard extends StatelessWidget {
  const _DaySummaryCard({
    required this.day,
    required this.prises,
    required this.l10n,
  });

  final DateTime day;
  final List<PriseDuJour> prises;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final taken = prises.where((p) => p.isTaken).length;

    return PremiumCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  HomeDashboardScreen._prettyDate(context, day),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  prises.isEmpty
                      ? l10n.homeNoDoses
                      : l10n.homeWeekSummary(taken, prises.length),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    height: 1.35,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (prises.isNotEmpty) ...[
            const SizedBox(width: 12),
            DayRing(
              done: taken,
              total: prises.length,
              trackColor: tokens.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFEEF2F7),
              progressColor: AppColors.primary,
              labelColor: tokens.textPrimary,
              size: 56,
              stroke: 5,
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorCard extends ConsumerWidget {
  const _ErrorCard({required this.message, required this.l10n});

  final String message;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            style: TextStyle(color: ThemeTokens.of(context).textSecondary),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => ref.read(homeControllerProvider.notifier).load(),
            child: Text(l10n.onboardingRetry),
          ),
        ],
      ),
    );
  }
}

class _ActivateBanner extends ConsumerWidget {
  const _ActivateBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(homeControllerProvider).busy;
    return _CtaBanner(
      icon: IconsaxPlusLinear.health,
      title: l10n.homeActivateTitle,
      subtitle: l10n.homeActivateBody,
      onTap: busy
          ? () {}
          : () async {
              try {
                await ref
                    .read(homeControllerProvider.notifier)
                    .activateFollowUp();
                if (context.mounted) context.push('/home/traitement');
              } catch (e) {
                if (context.mounted) {
                  AppToast.error(
                    context,
                    e is ApiException ? e.message : l10n.genericError,
                  );
                }
              }
            },
    );
  }
}
