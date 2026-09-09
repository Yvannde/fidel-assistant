import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/home_controller.dart';
import '../domain/profile_settings_models.dart';
import 'widgets/home_skeleton.dart';

/// Préférences consentement — Volet 7 (`toujours_demander` / `regle_auto` opt-in).
class ProfileConsentScreen extends ConsumerStatefulWidget {
  const ProfileConsentScreen({super.key});

  @override
  ConsumerState<ProfileConsentScreen> createState() =>
      _ProfileConsentScreenState();
}

class _ProfileConsentScreenState extends ConsumerState<ProfileConsentScreen> {
  List<PreferenceConsentement> _prefs = const [];
  bool _loading = true;
  String? _busyType;

  static const _hidden = {'sos_declenche', 'aidant_sync', 'education_contextuelle'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list =
          await ref.read(homeRepositoryProvider).listPreferencesConsentement();
      if (mounted) {
        setState(() {
          _prefs = list.where((p) => !_hidden.contains(p.typeAlerte)).toList();
        });
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      AppToast.error(
        context,
        e is ApiException ? e.message : l10n.genericError,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _label(AppLocalizations l10n, String type) {
    return switch (type) {
      'rappel_medicament' => l10n.profileAlertRappelMed,
      'stock_medicament_bas' => l10n.profileAlertStock,
      'constante_amelioration' => l10n.profileAlertConstanteUp,
      'constante_degradation' => l10n.profileAlertConstanteDown,
      'checkin_absence' => l10n.profileAlertCheckin,
      'depistage_recommande' => l10n.profileAlertDepistage,
      _ => type,
    };
  }

  Future<void> _setToujoursDemander(PreferenceConsentement p, bool value) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busyType = p.typeAlerte);
    try {
      Map<String, dynamic>? regle;
      if (!value &&
          PreferenceConsentement.configurableAutoTypes.contains(p.typeAlerte)) {
        // Opt-in explicite — jamais pré-coché sans geste.
        regle = {'delai_heures': 48};
      }
      final updated = await ref
          .read(homeRepositoryProvider)
          .patchPreferenceConsentement(
            typeAlerte: p.typeAlerte,
            toujoursDemander: value,
            regleAuto: regle,
          );
      setState(() {
        _prefs = [
          for (final item in _prefs)
            if (item.typeAlerte == p.typeAlerte) updated else item,
        ];
      });
      if (mounted) AppToast.success(context, l10n.profileSaved);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        e is ApiException ? e.message : l10n.genericError,
      );
    } finally {
      if (mounted) setState(() => _busyType = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);

    return DawnBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(l10n.profileConsentTitle),
        ),
        body: _loading
            ? const ProfilePageSkeleton(rows: 5)
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Text(
                    l10n.profileConsentHint,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: tokens.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  PremiumCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < _prefs.length; i++) ...[
                          SwitchListTile(
                            title: Text(_label(l10n, _prefs[i].typeAlerte)),
                            subtitle: Text(
                              _prefs[i].toujoursDemander
                                  ? l10n.profileConsentAlwaysAsk
                                  : l10n.profileConsentAutoHint,
                            ),
                            value: _prefs[i].toujoursDemander,
                            onChanged: _busyType == _prefs[i].typeAlerte
                                ? null
                                : (v) => _setToujoursDemander(_prefs[i], v),
                          ),
                          if (i < _prefs.length - 1) const Divider(height: 1),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
