import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/home_controller.dart';
import '../domain/profile_settings_models.dart';
import 'widgets/home_skeleton.dart';

/// Réglages patient — `GET/PATCH /patients/me`.
class ProfilePatientSettingsScreen extends ConsumerStatefulWidget {
  const ProfilePatientSettingsScreen({super.key});

  @override
  ConsumerState<ProfilePatientSettingsScreen> createState() =>
      _ProfilePatientSettingsScreenState();
}

class _ProfilePatientSettingsScreenState
    extends ConsumerState<ProfilePatientSettingsScreen> {
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

  Future<void> _patch({
    bool? notificationsAccordees,
    bool? batterieExemptee,
    bool? notificationsDiscretes,
  }) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final s = await ref.read(homeRepositoryProvider).patchPatientSettings(
            notificationsAccordees: notificationsAccordees,
            batterieExemptee: batterieExemptee,
            notificationsDiscretes: notificationsDiscretes,
          );
      if (mounted) {
        setState(() => _settings = s);
        AppToast.success(context, l10n.profileSaved);
      }
      await ref.read(homeControllerProvider.notifier).load();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        e is ApiException ? e.message : l10n.genericError,
      );
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final s = _settings;

    return DawnBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
                    title: Text(l10n.profilePatientSettingsTitle),
        ),
        body: _loading
            ? const ProfilePageSkeleton(rows: 3)
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Text(
                    l10n.profilePatientSettingsHint,
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
                        SwitchListTile(
                          title: Text(l10n.profileNotifGranted),
                          subtitle: Text(l10n.profileNotifGrantedHint),
                          value: s?.notificationsAccordees ?? false,
                          onChanged: _busy
                              ? null
                              : (v) => _patch(notificationsAccordees: v),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: Text(l10n.profileBatteryExempt),
                          subtitle: Text(l10n.profileBatteryExemptHint),
                          value: s?.batterieExemptee ?? false,
                          onChanged: _busy
                              ? null
                              : (v) {
                                  if (v) {
                                    context.push('/onboarding/permissions');
                                  } else {
                                    _patch(batterieExemptee: false);
                                  }
                                },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: Text(l10n.profileDiscreteNotif),
                          subtitle: Text(l10n.profileDiscreteNotifHint),
                          value: s?.notificationsDiscretes ?? false,
                          onChanged: _busy
                              ? null
                              : (v) => _patch(notificationsDiscretes: v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
