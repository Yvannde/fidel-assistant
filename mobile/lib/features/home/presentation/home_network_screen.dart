import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/cercle_controller.dart';
import '../application/home_controller.dart';
import '../domain/aidant_models.dart';
import 'widgets/home_skeleton.dart';

class HomeNetworkScreen extends ConsumerStatefulWidget {
  const HomeNetworkScreen({super.key});

  @override
  ConsumerState<HomeNetworkScreen> createState() => _HomeNetworkScreenState();
}

class _HomeNetworkScreenState extends ConsumerState<HomeNetworkScreen> {
  Timer? _sosTicker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cercleControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _sosTicker?.cancel();
    super.dispose();
  }

  Future<void> _triggerSos() async {
    final l10n = AppLocalizations.of(context);
    final cercle = ref.read(cercleControllerProvider.notifier);
    try {
      final ticket = await cercle.triggerSos();
      if (!mounted) return;
      _showSosSheet(ticket);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        e is ApiException ? e.message : l10n.genericError,
      );
    }
  }

  Future<void> _showSosSheet(SosTicket ticket) async {
    final notifier = ref.read(cercleControllerProvider.notifier);
    _sosTicker?.cancel();
    _sosTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final remaining = ticket.annulableJusquA.difference(DateTime.now());
          if (remaining.isNegative) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.canPop(ctx)) Navigator.pop(ctx);
            });
          } else {
            _sosTicker?.cancel();
            _sosTicker = Timer.periodic(const Duration(seconds: 1), (_) {
              if (!mounted) return;
              setState(() {});
              setModalState(() {});
            });
          }
          final seconds = remaining.isNegative ? 0 : remaining.inSeconds + 1;
          return _SosSheet(
            secondsLeft: seconds,
            onCancel: () async {
              final l10n = AppLocalizations.of(context);
              try {
                final msg = await notifier.cancelSos(ticket.id);
                if (!mounted || !ctx.mounted) return;
                AppToast.success(context, msg.isEmpty ? l10n.cercleSosCancelled : msg);
                Navigator.pop(ctx);
              } catch (e) {
                if (!mounted) return;
                AppToast.error(
                  context,
                  e is ApiException ? e.message : l10n.genericError,
                );
              }
            },
          );
        },
      ),
    );
    _sosTicker?.cancel();
    notifier.clearSosState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final profile = ref.watch(homeControllerProvider).profile;
    final cercle = ref.watch(cercleControllerProvider);
    final hasPatient = profile?.hasPatientProfile == true;
    final isAidant = profile?.isAidant == true;
    final padTop = 12 + MediaQuery.paddingOf(context).top;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(cercleControllerProvider.notifier).load(),
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
            l10n.navPeople,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.homeNetworkSubtitle,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: tokens.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          if (cercle.loading)
            const HomeCareSkeleton()
          else ...[
            if (cercle.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  cercle.error!,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: tokens.textSecondary,
                  ),
                ),
              ),
            if (isAidant) ...[
              _SectionLabel(title: l10n.cercleMyPatients),
              const SizedBox(height: 8),
              if (cercle.accompaniedPatients.isEmpty)
                _EmptyCard(
                  title: l10n.cercleMyPatientsEmptyTitle,
                  body: l10n.cercleMyPatientsEmptyBody,
                  cta: l10n.homeAccompanyTitle,
                  onTap: () => context.push('/home/sync'),
                )
              else
                PremiumCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < cercle.accompaniedPatients.length; i++) ...[
                        _PatientTile(
                          patient: cercle.accompaniedPatients[i],
                          onTap: () => context.push(
                            '/home/cercle/patient/${cercle.accompaniedPatients[i].id}',
                            extra: cercle.accompaniedPatients[i],
                          ),
                        ),
                        if (i < cercle.accompaniedPatients.length - 1)
                          Divider(height: 1, indent: 72, color: tokens.border),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 18),
            ],
            if (hasPatient) ...[
              _SectionLabel(title: l10n.cercleMyCircle),
              const SizedBox(height: 8),
              PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.cercleMyCircleHint,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14,
                        height: 1.4,
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _MiniStatRow(
                      icon: IconsaxPlusLinear.people,
                      title: l10n.homeAidantsTitle,
                      value: '${cercle.aidants.length}',
                    ),
                    const SizedBox(height: 10),
                    _MiniStatRow(
                      icon: IconsaxPlusLinear.call,
                      title: l10n.profileContactsTitle,
                      value: '${cercle.contactsCount}',
                    ),
                    const SizedBox(height: 16),
                    if (cercle.aidants.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final aidant in cercle.aidants.take(3))
                            _NameChip(label: aidant.displayName),
                        ],
                      ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: cercle.busy
                            ? null
                            : (cercle.hasContacts
                                  ? _triggerSos
                                  : () => context.push('/home/profile/contacts')),
                        style: FilledButton.styleFrom(
                          backgroundColor: cercle.hasContacts
                              ? Theme.of(context).colorScheme.error
                              : AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        icon: Icon(
                          cercle.hasContacts
                              ? IconsaxPlusLinear.warning_2
                              : IconsaxPlusLinear.add_circle,
                        ),
                        label: Text(
                          cercle.hasContacts
                              ? l10n.cercleSosTitle
                              : l10n.cercleAddEmergencyContact,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
            if (!hasPatient && !isAidant)
              _EmptyCercleState(
                onActivate: () => ref.read(homeTabIndexProvider.notifier).state = 0,
                onSync: () => context.push('/home/sync'),
              ),
            if (hasPatient || isAidant) ...[
              _SectionLabel(title: l10n.cercleQuickLinks),
              const SizedBox(height: 8),
              PremiumCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    if (isAidant)
                      _LinkTile(
                        icon: IconsaxPlusLinear.scan_barcode,
                        title: l10n.homeAccompanyTitle,
                        subtitle: l10n.cercleLinkSyncHint,
                        onTap: () => context.push('/home/sync'),
                      ),
                    if (hasPatient)
                      _LinkTile(
                        icon: IconsaxPlusLinear.people,
                        title: l10n.homeShareCodeTitle,
                        subtitle: l10n.cercleLinkAidantsHint,
                        onTap: () => context.push('/home/aidants'),
                        showDivider: false,
                      )
                    else if (isAidant)
                      const SizedBox.shrink(),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
        color: ThemeTokens.of(context).textSecondary,
      ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  const _PatientTile({required this.patient, required this.onTap});

  final AidantPatient patient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    String subtitle;
    if (patient.permissions.observance && patient.permissions.constantes) {
      subtitle = l10n.homeAidantsPermBoth;
    } else if (patient.permissions.observance) {
      subtitle = l10n.homeAidantsPermObservanceOnly;
    } else if (patient.permissions.constantes) {
      subtitle = l10n.homeAidantsPermConstantes;
    } else {
      subtitle = l10n.cerclePermissionLimited;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(
                    alpha: tokens.isDark ? 0.2 : 0.1,
                  ),
                ),
                child: Text(
                  patient.initial,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.displayName,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                IconsaxPlusLinear.arrow_right_3,
                color: AppColors.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStatRow extends StatelessWidget {
  const _MiniStatRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: tokens.isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(Premium.radiusSm),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                color: tokens.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NameChip extends StatelessWidget {
  const _NameChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: tokens.isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.title,
    required this.body,
    required this.cta,
    required this.onTap,
  });

  final String title;
  final String body;
  final String cta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14,
              height: 1.4,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(cta),
          ),
        ],
      ),
    );
  }
}

class _EmptyCercleState extends StatelessWidget {
  const _EmptyCercleState({
    required this.onActivate,
    required this.onSync,
  });

  final VoidCallback onActivate;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.cercleEmptyTitle,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.cercleEmptyBody,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14,
              height: 1.4,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onActivate,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(l10n.homeActivateTitle),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: onSync,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(l10n.homeAccompanyTitle),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    IconsaxPlusLinear.arrow_right_3,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider) Divider(height: 1, indent: 46, color: tokens.border),
      ],
    );
  }
}

class _SosSheet extends StatelessWidget {
  const _SosSheet({
    required this.secondsLeft,
    required this.onCancel,
  });

  final int secondsLeft;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: tokens.isDark ? tokens.elevated : Colors.white,
            borderRadius: BorderRadius.circular(Premium.radius),
          ),
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.cercleSosSent,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.cercleSosCountdown(secondsLeft),
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14,
                  height: 1.4,
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: onCancel,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    l10n.cercleSosCancel,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
