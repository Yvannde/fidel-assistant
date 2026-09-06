import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/premium.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/application/home_controller.dart';
import '../../medicaments/data/medicaments_repository.dart';
import '../../onboarding/domain/onboarding_models.dart';
import '../../onboarding/presentation/widgets/onboarding_option_tile.dart';

class AddTraitementScreen extends ConsumerStatefulWidget {
  const AddTraitementScreen({super.key});

  @override
  ConsumerState<AddTraitementScreen> createState() => _AddTraitementScreenState();
}

class _AddTraitementScreenState extends ConsumerState<AddTraitementScreen> {
  List<MaladieCatalogItem> _maladies = const [];
  String? _maladieId;
  String _phase = 'en_cours';
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final items =
          await ref.read(medicamentsRepositoryProvider).listMaladies();
      if (!mounted) return;
      setState(() {
        _maladies = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppToast.error(
        context,
        e is ApiException ? e.message : AppLocalizations.of(context).genericError,
      );
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_maladieId == null) {
      AppToast.error(context, l10n.onboardingMaladieRequired);
      return;
    }
    setState(() => _busy = true);
    try {
      final id = await ref.read(medicamentsRepositoryProvider).createTraitement(
            maladieId: _maladieId!,
            phase: _phase,
          );
      await ref.read(homeControllerProvider.notifier).load();
      if (!mounted) return;
      context.pushReplacement('/home/medicaments', extra: id);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        e is ApiException ? e.message : l10n.genericError,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DawnBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(l10n.homeActionTraitementTitle),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
                children: [
                  Text(
                    l10n.onboardingMaladiesLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  for (final m in _maladies)
                    OnboardingOptionTile(
                      selected: _maladieId == m.id,
                      title: m.nom,
                      onTap: () => setState(() => _maladieId = m.id),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.onboardingPhaseLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                      selected: _phase == entry.$1,
                      title: entry.$2,
                      onTap: () => setState(() => _phase = entry.$1),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(l10n.onboardingContinue),
                  ),
                ],
              ),
      ),
    );
  }
}
