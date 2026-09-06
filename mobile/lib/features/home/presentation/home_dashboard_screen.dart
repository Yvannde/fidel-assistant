import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/premium.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/home_controller.dart';
import '../domain/dashboard_models.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final now = DateTime.now();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(homeControllerProvider.notifier).load(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              22,
              12 + MediaQuery.paddingOf(context).top,
              22,
              Premium.navClearance,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _Greeting(
                  name: state.profile?.firstName ?? '',
                  l10n: l10n,
                ),
                const SizedBox(height: 22),
                if (state.loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.error != null && state.profile == null)
                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(state.error!, style: TextStyle(color: tokens.textSecondary)),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () =>
                              ref.read(homeControllerProvider.notifier).load(),
                          child: Text(l10n.onboardingRetry),
                        ),
                      ],
                    ),
                  )
                else if (!state.hasPatient)
                  _CapabilityHome(l10n: l10n)
                else ...[
                  _HeroCard(dashboard: state.dashboard, now: now, l10n: l10n),
                  const SizedBox(height: 16),
                  _StatRow(dashboard: state.dashboard, now: now, l10n: l10n),
                  const SizedBox(height: 22),
                  Text(
                    l10n.homeTodayTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _TodayList(dashboard: state.dashboard, now: now, l10n: l10n),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name, required this.l10n});

  final String name;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final String hello;
    if (name.isEmpty) {
      hello = hour < 12
          ? l10n.homeHelloMorningAnon
          : hour < 18
              ? l10n.homeHelloAfternoonAnon
              : l10n.homeHelloEveningAnon;
    } else {
      hello = hour < 12
          ? l10n.homeHelloMorning(name)
          : hour < 18
              ? l10n.homeHelloAfternoon(name)
              : l10n.homeHelloEvening(name);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hello,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.15,
                letterSpacing: -0.6,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.homeTagline,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: ThemeTokens.of(context).textSecondary,
                height: 1.4,
              ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.dashboard,
    required this.now,
    required this.l10n,
  });

  final PatientDashboard? dashboard;
  final DateTime now;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final action = dashboard?.prochaineAction;
    if (action == 'activer_notifications') {
      return PremiumCard(
        onTap: () => context.push('/onboarding/permissions'),
        child: _CtaBody(
          icon: Icons.notifications_active_rounded,
          title: l10n.homeActionNotifTitle,
          subtitle: l10n.homeActionNotifBody,
        ),
      );
    }
    if (action == 'configurer_medicaments' ||
        (dashboard?.traitements.isNotEmpty == true &&
            dashboard?.medicamentsConfigures == false)) {
      final t = dashboard?.firstUnconfigured;
      return PremiumCard(
        onTap: t == null
            ? null
            : () => context.push('/home/medicaments', extra: t.id),
        child: _CtaBody(
          icon: Icons.medication_liquid_rounded,
          title: l10n.homeActionMedsTitle,
          subtitle: t == null
              ? l10n.homeActionMedsBody
              : l10n.homeActionMedsFor(t.maladieNom),
        ),
      );
    }
    if (dashboard != null && dashboard!.traitements.isEmpty) {
      return PremiumCard(
        onTap: () => context.push('/home/traitement'),
        child: _CtaBody(
          icon: Icons.favorite_rounded,
          title: l10n.homeActionTraitementTitle,
          subtitle: l10n.homeActionTraitementBody,
        ),
      );
    }

    final next = dashboard?.nextDose(now);
    if (next == null) {
      return PremiumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.homeAllClearTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.homeAllClearBody,
              style: TextStyle(color: ThemeTokens.of(context).textSecondary),
            ),
          ],
        ),
      );
    }

    final time = DateFormat.Hm().format(next.heurePrevue.toLocal());
    return PremiumCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeNextDoseLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ThemeTokens.of(context).textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1,
                        letterSpacing: -1.4,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${next.medicamentNom} · ${next.dosage}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaBody extends StatelessWidget {
  const _CtaBody({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: ThemeTokens.of(context).textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.dashboard,
    required this.now,
    required this.l10n,
  });

  final PatientDashboard? dashboard;
  final DateTime now;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final pending = dashboard?.pendingCount(now) ?? 0;
    final taken = dashboard?.takenCount() ?? 0;
    final late = dashboard?.lateCount(now) ?? 0;
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            label: l10n.homeStatPending,
            value: '$pending',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            label: l10n.homeStatTaken,
            value: '$taken',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            label: l10n.homeStatLate,
            value: '$late',
            color: late > 0 ? AppColors.error : ThemeTokens.of(context).textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _TodayList extends ConsumerWidget {
  const _TodayList({
    required this.dashboard,
    required this.now,
    required this.l10n,
  });

  final PatientDashboard? dashboard;
  final DateTime now;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prises = dashboard?.prisesAujourdhui ?? const <PriseDuJour>[];
    if (prises.isEmpty) {
      return PremiumCard(
        child: Text(
          l10n.homeNoDoses,
          style: TextStyle(color: ThemeTokens.of(context).textSecondary),
        ),
      );
    }

    return PremiumCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < prises.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _PriseTile(prise: prises[i], now: now, l10n: l10n),
          ],
        ],
      ),
    );
  }
}

class _PriseTile extends ConsumerWidget {
  const _PriseTile({
    required this.prise,
    required this.now,
    required this.l10n,
  });

  final PriseDuJour prise;
  final DateTime now;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = DateFormat.Hm().format(prise.heurePrevue.toLocal());
    final late = prise.isLate(now);
    final busy = ref.watch(homeControllerProvider).busy;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: prise.isTaken
            ? AppColors.success.withValues(alpha: 0.15)
            : late
                ? AppColors.error.withValues(alpha: 0.12)
                : AppColors.primary.withValues(alpha: 0.12),
        child: Icon(
          prise.isTaken
              ? Icons.check_rounded
              : Icons.medication_rounded,
          color: prise.isTaken
              ? AppColors.success
              : late
                  ? AppColors.error
                  : AppColors.primary,
        ),
      ),
      title: Text(
        prise.medicamentNom,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text('$time · ${prise.dosage}'),
      trailing: prise.isPending
          ? TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      try {
                        await ref
                            .read(homeControllerProvider.notifier)
                            .confirmPrise(prise.id);
                        if (context.mounted) {
                          AppToast.success(context, l10n.homeTakenToast);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          AppToast.error(
                            context,
                            e is ApiException ? e.message : l10n.genericError,
                          );
                        }
                      }
                    },
              child: Text(l10n.homeTakeCta),
            )
          : Text(
              l10n.homeTakenBadge,
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

class _CapabilityHome extends ConsumerWidget {
  const _CapabilityHome({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(homeControllerProvider).busy;
    return Column(
      children: [
        PremiumCard(
          onTap: busy
              ? null
              : () async {
                  try {
                    await ref
                        .read(homeControllerProvider.notifier)
                        .activateFollowUp();
                    if (context.mounted) {
                      context.push('/home/traitement');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppToast.error(
                        context,
                        e is ApiException ? e.message : l10n.genericError,
                      );
                    }
                  }
                },
          child: _CtaBody(
            icon: Icons.favorite_rounded,
            title: l10n.homeActivateTitle,
            subtitle: l10n.homeActivateBody,
          ),
        ),
      ],
    );
  }
}
