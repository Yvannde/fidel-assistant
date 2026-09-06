import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/onboarding_controller.dart';
import 'widgets/onboarding_choice_card.dart';
import 'widgets/onboarding_shell.dart';

class OnboardingBesoinSuiviScreen extends ConsumerStatefulWidget {
  const OnboardingBesoinSuiviScreen({super.key});

  @override
  ConsumerState<OnboardingBesoinSuiviScreen> createState() =>
      _OnboardingBesoinSuiviScreenState();
}

class _OnboardingBesoinSuiviScreenState
    extends ConsumerState<OnboardingBesoinSuiviScreen> {
  String? _error;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final actif = ref.read(onboardingControllerProvider).besoinActif;
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
    final state = ref.watch(onboardingControllerProvider);
    final actif = state.besoinActif;

    return OnboardingShell(
      stepIndex: 1,
      title: l10n.onboardingBesoinTitle,
      subtitle: l10n.onboardingBesoinSubtitle,
      lottieAsset: 'assets/lottie/care_self.json',
      lottieIcon: Icons.favorite_rounded,
      primaryLabel: l10n.onboardingContinue,
      primaryEnabled: actif != null,
      busy: state.busy,
      onBack: () => context.go('/onboarding/infos'),
      onPrimary: _submit,
      child: Column(
        children: [
          OnboardingChoiceCard(
            selected: actif == true,
            title: l10n.onboardingBesoinYesTitle,
            subtitle: l10n.onboardingBesoinYesSubtitle,
            icon: Icons.monitor_heart_outlined,
            onTap: state.busy
                ? null
                : () {
                    ref
                        .read(onboardingControllerProvider.notifier)
                        .setBesoinDraft(true);
                    setState(() => _error = null);
                  },
          ),
          const SizedBox(height: 12),
          OnboardingChoiceCard(
            selected: actif == false,
            title: l10n.onboardingBesoinNoTitle,
            subtitle: l10n.onboardingBesoinNoSubtitle,
            icon: Icons.people_outline_rounded,
            onTap: state.busy
                ? null
                : () {
                    ref
                        .read(onboardingControllerProvider.notifier)
                        .setBesoinDraft(false);
                    setState(() => _error = null);
                  },
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
