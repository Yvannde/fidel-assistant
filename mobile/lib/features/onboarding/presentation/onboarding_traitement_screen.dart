import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/onboarding_controller.dart';
import '../domain/onboarding_models.dart';
import 'widgets/onboarding_shell.dart';

class OnboardingTraitementScreen extends ConsumerStatefulWidget {
  const OnboardingTraitementScreen({super.key});

  @override
  ConsumerState<OnboardingTraitementScreen> createState() =>
      _OnboardingTraitementScreenState();
}

class _OnboardingTraitementScreenState
    extends ConsumerState<OnboardingTraitementScreen> {
  bool? _enTraitement;
  final _selected = <String>{};
  String _phase = 'en_cours';
  String? _error;
  bool _loadingMaladies = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadingMaladies = true);
    try {
      await ref.read(onboardingControllerProvider.notifier).loadMaladies();
    } catch (_) {
      // Catalog optional until submit with traitements.
    } finally {
      if (mounted) setState(() => _loadingMaladies = false);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_enTraitement == null) {
      setState(() => _error = l10n.onboardingChoiceRequired);
      return;
    }
    if (_enTraitement == true && _selected.isEmpty) {
      setState(() => _error = l10n.onboardingMaladieRequired);
      return;
    }
    setState(() => _error = null);
    try {
      final traitements = _enTraitement == true
          ? _selected
              .map(
                (id) => TraitementSelection(maladieId: id, phase: _phase),
              )
              .toList()
          : null;
      await ref.read(onboardingControllerProvider.notifier).saveTraitement(
            enTraitement: _enTraitement!,
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
    final theme = Theme.of(context);
    final tokens = ThemeTokens.of(context);

    return OnboardingShell(
      title: l10n.onboardingTraitementTitle,
      subtitle: l10n.onboardingTraitementSubtitle,
      progress: 0.75,
      lottieAsset: 'assets/lottie/meds.json',
      lottieIcon: Icons.medication_liquid_rounded,
      primaryLabel: l10n.onboardingContinue,
      primaryEnabled: _enTraitement != null,
      busy: state.busy,
      onBack: () => context.go('/onboarding/besoin-suivi'),
      onPrimary: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ChoiceChip(
                label: Text(l10n.onboardingTraitementYes),
                selected: _enTraitement == true,
                onSelected: state.busy
                    ? null
                    : (_) => setState(() => _enTraitement = true),
              ),
              ChoiceChip(
                label: Text(l10n.onboardingTraitementNo),
                selected: _enTraitement == false,
                onSelected: state.busy
                    ? null
                    : (_) => setState(() {
                          _enTraitement = false;
                          _selected.clear();
                        }),
              ),
            ],
          ),
          if (_enTraitement == true) ...[
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
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.maladies.map((m) {
                  final selected = _selected.contains(m.id);
                  return FilterChip(
                    label: Text(m.nom),
                    selected: selected,
                    onSelected: state.busy
                        ? null
                        : (v) => setState(() {
                              if (v) {
                                _selected.add(m.id);
                              } else {
                                _selected.remove(m.id);
                              }
                            }),
                    selectedColor:
                        AppColors.primary.withValues(alpha: 0.18),
                    checkmarkColor: AppColors.primary,
                  );
                }).toList(),
              ),
            const SizedBox(height: 18),
            Text(
              l10n.onboardingPhaseLabel,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in [
                  ('debut', l10n.onboardingPhaseDebut),
                  ('en_cours', l10n.onboardingPhaseEnCours),
                  ('maintenance', l10n.onboardingPhaseMaintenance),
                  ('inconnu', l10n.onboardingPhaseInconnu),
                ])
                  ChoiceChip(
                    label: Text(entry.$2),
                    selected: _phase == entry.$1,
                    onSelected: state.busy
                        ? null
                        : (_) => setState(() => _phase = entry.$1),
                  ),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          if (_enTraitement == false)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                l10n.onboardingTraitementNoHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
