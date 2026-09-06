import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/onboarding_controller.dart';
import '../domain/onboarding_models.dart';
import 'widgets/onboarding_choice_card.dart';
import 'widgets/onboarding_option_tile.dart';
import 'widgets/onboarding_shell.dart';

class OnboardingTraitementScreen extends ConsumerStatefulWidget {
  const OnboardingTraitementScreen({super.key});

  @override
  ConsumerState<OnboardingTraitementScreen> createState() =>
      _OnboardingTraitementScreenState();
}

class _OnboardingTraitementScreenState
    extends ConsumerState<OnboardingTraitementScreen> {
  String? _error;
  var _loadingMaladies = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loadingMaladies = true);
    try {
      await ref.read(onboardingControllerProvider.notifier).loadMaladies();
    } catch (_) {
      // Retry affiché dans l’UI.
    } finally {
      if (mounted) setState(() => _loadingMaladies = false);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final draft = ref.read(onboardingControllerProvider).traitement;
    if (draft.enTraitement == null) {
      setState(() => _error = l10n.onboardingChoiceRequired);
      return;
    }
    if (draft.enTraitement == true && draft.maladieIds.isEmpty) {
      setState(() => _error = l10n.onboardingMaladieRequired);
      return;
    }
    setState(() => _error = null);
    try {
      final traitements = draft.enTraitement == true
          ? draft.maladieIds
              .map(
                (id) => TraitementSelection(maladieId: id, phase: draft.phase),
              )
              .toList()
          : null;
      await ref.read(onboardingControllerProvider.notifier).saveTraitement(
            enTraitement: draft.enTraitement!,
            traitements: traitements,
          );
      if (!mounted) return;
      context.go('/onboarding/permissions');
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
    final draft = state.traitement;
    final theme = Theme.of(context);

    return OnboardingShell(
      stepIndex: 2,
      title: l10n.onboardingTraitementTitle,
      subtitle: l10n.onboardingTraitementSubtitle,
      lottieAsset: 'assets/lottie/meds.json',
      lottieIcon: Icons.medication_liquid_rounded,
      lottieSize: 156,
      primaryLabel: l10n.onboardingContinue,
      primaryEnabled: draft.enTraitement != null,
      busy: state.busy,
      onBack: () => context.go('/onboarding/besoin-suivi'),
      onPrimary: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingChoiceCard(
            selected: draft.enTraitement == true,
            title: l10n.onboardingTraitementYes,
            subtitle: l10n.onboardingTraitementYesSubtitle,
            icon: Icons.medication_outlined,
            onTap: state.busy
                ? null
                : () {
                    ref
                        .read(onboardingControllerProvider.notifier)
                        .setTraitementDraft(
                          draft.copyWith(enTraitement: true),
                        );
                    setState(() => _error = null);
                  },
          ),
          const SizedBox(height: 12),
          OnboardingChoiceCard(
            selected: draft.enTraitement == false,
            title: l10n.onboardingTraitementNo,
            subtitle: l10n.onboardingTraitementNoSubtitle,
            icon: Icons.hourglass_empty_rounded,
            onTap: state.busy
                ? null
                : () {
                    ref
                        .read(onboardingControllerProvider.notifier)
                        .setTraitementDraft(
                          draft.copyWith(
                            enTraitement: false,
                            maladieIds: {},
                          ),
                        );
                    setState(() => _error = null);
                  },
          ),
          if (draft.enTraitement == true) ...[
            const SizedBox(height: 22),
            Text(
              l10n.onboardingMaladiesLabel,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (_loadingMaladies)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.maladiesFailed || state.maladies.isEmpty)
              Column(
                children: [
                  Text(
                    l10n.onboardingMaladiesEmpty,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: state.busy ? null : _load,
                    child: Text(l10n.onboardingRetry),
                  ),
                ],
              )
            else
              ...state.maladies.map((m) {
                final selected = draft.maladieIds.contains(m.id);
                return OnboardingOptionTile(
                  title: m.nom,
                  subtitle: m.description,
                  selected: selected,
                  multi: true,
                  onTap: state.busy
                      ? null
                      : () {
                          final next = {...draft.maladieIds};
                          if (selected) {
                            next.remove(m.id);
                          } else {
                            next.add(m.id);
                          }
                          ref
                              .read(onboardingControllerProvider.notifier)
                              .setTraitementDraft(
                                draft.copyWith(maladieIds: next),
                              );
                        },
                );
              }),
            const SizedBox(height: 8),
            Text(
              l10n.onboardingPhaseLabel,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            for (final entry in [
              ('debut', l10n.onboardingPhaseDebut),
              ('en_cours', l10n.onboardingPhaseEnCours),
              ('maintenance', l10n.onboardingPhaseMaintenance),
              ('inconnu', l10n.onboardingPhaseInconnu),
            ])
              OnboardingOptionTile(
                title: entry.$2,
                selected: draft.phase == entry.$1,
                onTap: state.busy
                    ? null
                    : () {
                        ref
                            .read(onboardingControllerProvider.notifier)
                            .setTraitementDraft(
                              draft.copyWith(phase: entry.$1),
                            );
                      },
              ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
