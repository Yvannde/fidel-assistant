import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/home_controller.dart';
import '../domain/profile_settings_models.dart';
import 'widgets/home_skeleton.dart';
import 'widgets/profile_settings_tile.dart';

/// Fiche santé identité — selects fermés + confirmation avant PATCH.
class ProfileFicheSanteScreen extends ConsumerStatefulWidget {
  const ProfileFicheSanteScreen({super.key});

  @override
  ConsumerState<ProfileFicheSanteScreen> createState() =>
      _ProfileFicheSanteScreenState();
}

class _ProfileFicheSanteScreenState
    extends ConsumerState<ProfileFicheSanteScreen> {
  PatientSettings? _settings;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await ref.read(homeRepositoryProvider).fetchPatientSettings();
      if (mounted) setState(() => _settings = s);
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

  Future<void> _applySettings(PatientSettings s) async {
    setState(() => _settings = s);
    final profile = ref.read(homeControllerProvider).profile;
    if (profile != null) {
      await ref.read(homeControllerProvider.notifier).updateProfile(
            profile.copyWith(
              groupeSanguin: s.groupeSanguin,
              rhesus: s.rhesus,
              electrophorese: s.electrophorese,
              tailleCm: s.tailleCm,
            ),
          );
    }
  }

  String _groupeLabel(AppLocalizations l10n) {
    final s = _settings;
    if (s?.groupeSanguin == null || s?.rhesus == null) {
      return l10n.profileFicheSanteUnset;
    }
    return '${s!.groupeSanguin}${s.rhesus}';
  }

  String _electroLabel(AppLocalizations l10n) {
    final e = _settings?.electrophorese;
    if (e == null) return l10n.profileFicheSanteUnset;
    if (e == 'ne_sait_pas') return l10n.profileFicheSanteNeSaitPas;
    return e;
  }

  String _tailleLabel(AppLocalizations l10n) {
    final t = _settings?.tailleCm;
    if (t == null) return l10n.profileFicheSanteUnset;
    return l10n.profileFicheSanteTailleValue(t);
  }

  Future<bool> _confirm(String summary) async {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          color: tokens.elevated,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.profileFicheSanteConfirmTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.profileFicheSanteConfirmBody(summary),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.profileFicheSanteConfirmAction),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.profileFicheSanteCorrectAction),
            ),
          ],
        ),
      ),
    );
    return ok == true;
  }

  Future<T?> _pickFromList<T>({
    required String title,
    required List<T> values,
    required String Function(T) labelOf,
    T? selected,
  }) async {
    final tokens = ThemeTokens.of(context);
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.55,
        ),
        decoration: BoxDecoration(
          color: tokens.elevated,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: values.length,
                itemBuilder: (_, i) {
                  final v = values[i];
                  final selectedNow = selected == v;
                  return ListTile(
                    title: Text(labelOf(v)),
                    trailing: selectedNow
                        ? Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () => Navigator.pop(ctx, v),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editGroupeRhesus() async {
    final l10n = AppLocalizations.of(context);
    final groupe = await _pickFromList<String>(
      title: l10n.profileFicheSanteGroupePick,
      values: FicheSanteOptions.groupes,
      labelOf: (v) => v,
      selected: _settings?.groupeSanguin,
    );
    if (groupe == null || !mounted) return;
    final rhesus = await _pickFromList<String>(
      title: l10n.profileFicheSanteRhesusPick,
      values: FicheSanteOptions.rhesus,
      labelOf: (v) => v,
      selected: _settings?.rhesus,
    );
    if (rhesus == null || !mounted) return;
    final summary = '$groupe$rhesus';
    if (!await _confirm(summary)) return;
    await _patch(
      () => ref.read(homeRepositoryProvider).patchPatientSettings(
            groupeSanguin: groupe,
            rhesus: rhesus,
            confirmGroupeRhesus: true,
          ),
    );
  }

  Future<void> _editElectrophorese() async {
    final l10n = AppLocalizations.of(context);
    final value = await _pickFromList<String>(
      title: l10n.profileFicheSanteElectroPick,
      values: FicheSanteOptions.electrophoreses,
      labelOf: (v) =>
          v == 'ne_sait_pas' ? l10n.profileFicheSanteNeSaitPas : v,
      selected: _settings?.electrophorese,
    );
    if (value == null || !mounted) return;
    final summary =
        value == 'ne_sait_pas' ? l10n.profileFicheSanteNeSaitPas : value;
    if (!await _confirm(summary)) return;
    await _patch(
      () => ref.read(homeRepositoryProvider).patchPatientSettings(
            electrophorese: value,
            confirmElectrophorese: true,
          ),
    );
  }

  Future<void> _editTaille() async {
    final l10n = AppLocalizations.of(context);
    final value = await _pickFromList<int>(
      title: l10n.profileFicheSanteTaillePick,
      values: FicheSanteOptions.taillesCm,
      labelOf: (v) => l10n.profileFicheSanteTailleValue(v),
      selected: _settings?.tailleCm,
    );
    if (value == null || !mounted) return;
    if (!await _confirm(l10n.profileFicheSanteTailleValue(value))) return;
    await _patch(
      () => ref.read(homeRepositoryProvider).patchPatientSettings(
            tailleCm: value,
            confirmTaille: true,
          ),
    );
  }

  Future<void> _patch(Future<PatientSettings> Function() call) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final s = await call();
      if (!mounted) return;
      await _applySettings(s);
      if (!mounted) return;
      AppToast.success(context, l10n.profileSaved);
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
    final tokens = ThemeTokens.of(context);

    return DawnBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(l10n.profileFicheSanteTitle),
        ),
        body: _loading
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: HomeProfileSkeleton(),
              )
            : ListView(
                padding: EdgeInsets.fromLTRB(
                  Premium.screenPad,
                  12,
                  Premium.screenPad,
                  Premium.navClearance,
                ),
                children: [
                  Text(
                    l10n.profileFicheSanteHint,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: tokens.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ProfileSectionCard(
                    title: l10n.profileFicheSanteSection,
                    children: [
                      ProfileSettingsTile(
                        icon: IconsaxPlusLinear.drop,
                        title: l10n.profileFicheSanteGroupe,
                        subtitle: _groupeLabel(l10n),
                        onTap: _busy ? null : _editGroupeRhesus,
                      ),
                      ProfileSettingsTile(
                        icon: IconsaxPlusLinear.health,
                        title: l10n.profileFicheSanteElectro,
                        subtitle: _electroLabel(l10n),
                        onTap: _busy ? null : _editElectrophorese,
                      ),
                      ProfileSettingsTile(
                        icon: IconsaxPlusLinear.arrow_up_1,
                        title: l10n.profileFicheSanteTaille,
                        subtitle: _tailleLabel(l10n),
                        onTap: _busy ? null : _editTaille,
                        showDivider: false,
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
