import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/onboarding_controller.dart';
import 'widgets/onboarding_shell.dart';

class OnboardingBesoinSuiviScreen extends ConsumerStatefulWidget {
  const OnboardingBesoinSuiviScreen({super.key});

  @override
  ConsumerState<OnboardingBesoinSuiviScreen> createState() =>
      _OnboardingBesoinSuiviScreenState();
}

class _OnboardingBesoinSuiviScreenState
    extends ConsumerState<OnboardingBesoinSuiviScreen> {
  bool? _actif;
  String? _error;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final actif = _actif;
    if (actif == null) {
      setState(() => _error = l10n.onboardingChoiceRequired);
      return;
    }
    setState(() => _error = null);
    try {
      await ref
          .read(onboardingControllerProvider.notifier)
          .setBesoinSuivi(actif: actif);
      if (!mounted) return;
      if (actif) {
        context.go('/onboarding/traitement');
      } else {
        await ref.read(onboardingControllerProvider.notifier).complete();
        if (!mounted) return;
        AppToast.success(context, l10n.onboardingDoneToast);
        context.go('/home');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      AppToast.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.genericError);
      AppToast.error(context, l10n.genericError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final busy = ref.watch(onboardingControllerProvider).busy;

    return OnboardingShell(
      title: l10n.onboardingBesoinTitle,
      subtitle: l10n.onboardingBesoinSubtitle,
      progress: 0.5,
      lottieAsset: 'assets/lottie/care_self.json',
      lottieIcon: Icons.favorite_rounded,
      primaryLabel: l10n.onboardingContinue,
      primaryEnabled: _actif != null,
      busy: busy,
      onBack: () => context.go('/onboarding/infos'),
      onPrimary: _submit,
      child: Column(
        children: [
          _ChoiceCard(
            selected: _actif == true,
            title: l10n.onboardingBesoinYesTitle,
            subtitle: l10n.onboardingBesoinYesSubtitle,
            icon: Icons.monitor_heart_outlined,
            onTap: busy ? null : () => setState(() => _actif = true),
          ),
          const SizedBox(height: 12),
          _ChoiceCard(
            selected: _actif == false,
            title: l10n.onboardingBesoinNoTitle,
            subtitle: l10n.onboardingBesoinNoSubtitle,
            icon: Icons.people_outline_rounded,
            onTap: busy ? null : () => setState(() => _actif = false),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: tokens.isDark ? 0.22 : 0.08)
          : tokens.elevated,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.primary : tokens.border,
              width: selected ? 2 : 1.2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
                color: selected ? AppColors.primary : tokens.textSecondary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
