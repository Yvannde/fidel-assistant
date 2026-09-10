import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/alarm_prefs.dart';
import '../../../services/reminder_sync.dart';
import '../application/home_controller.dart';

/// Réglages locaux de l’alarme médicament (préavis, son, snooze, permissions).
class ProfileAlarmSettingsScreen extends ConsumerStatefulWidget {
  const ProfileAlarmSettingsScreen({super.key});

  @override
  ConsumerState<ProfileAlarmSettingsScreen> createState() =>
      _ProfileAlarmSettingsScreenState();
}

class _ProfileAlarmSettingsScreenState
    extends ConsumerState<ProfileAlarmSettingsScreen> {
  bool _exactOk = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refreshExact();
  }

  Future<void> _refreshExact() async {
    final ok =
        await ref.read(reminderAlarmServiceProvider).hasExactAlarmPermission();
    if (mounted) setState(() => _exactOk = ok);
  }

  Future<void> _afterChange() async {
    setState(() => _busy = true);
    try {
      final dash = ref.read(homeControllerProvider).dashboard;
      if (dash != null) {
        await syncRemindersFromHome(ref.read, dash, force: true);
      }
      if (mounted) {
        AppToast.success(context, AppLocalizations.of(context).profileSaved);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestExact() async {
    final ok = await ref
        .read(reminderAlarmServiceProvider)
        .ensureExactAlarmPermission();
    if (!ok && Platform.isAndroid) {
      await openAppSettings();
    }
    await _refreshExact();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final prefs = ref.watch(alarmPrefsProvider);

    return DawnBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(l10n.alarmSettingsTitle)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              l10n.alarmSettingsHint,
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
                  ListTile(
                    title: Text(l10n.alarmSettingsPreavis),
                    subtitle: Text(l10n.alarmSettingsPreavisHint),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SegmentedButton<int>(
                      segments: [
                        for (final m in AlarmPrefs.allowedPreavis)
                          ButtonSegment(
                            value: m,
                            label: Text(l10n.alarmSettingsMinutes(m)),
                          ),
                      ],
                      selected: {prefs.preavisMinutes},
                      onSelectionChanged: _busy
                          ? null
                          : (s) async {
                              await prefs.setPreavisMinutes(s.first);
                              setState(() {});
                              await _afterChange();
                            },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(l10n.alarmSettingsSnooze),
                    subtitle: Text(l10n.alarmSettingsSnoozeHint),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SegmentedButton<int>(
                      segments: [
                        for (final m in AlarmPrefs.allowedSnooze)
                          ButtonSegment(
                            value: m,
                            label: Text(l10n.alarmSettingsMinutes(m)),
                          ),
                      ],
                      selected: {prefs.snoozeMinutes},
                      onSelectionChanged: _busy
                          ? null
                          : (s) async {
                              await prefs.setSnoozeMinutes(s.first);
                              setState(() {});
                            },
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(l10n.alarmSettingsVibrate),
                    subtitle: Text(l10n.alarmSettingsVibrateHint),
                    value: prefs.vibrate,
                    onChanged: _busy
                        ? null
                        : (v) async {
                            await prefs.setVibrate(v);
                            setState(() {});
                            await _afterChange();
                          },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(l10n.alarmSettingsCustomVoice),
                    subtitle: Text(l10n.alarmSettingsCustomVoiceHint),
                    value: prefs.useCustomVoice,
                    onChanged: _busy
                        ? null
                        : (v) async {
                            if (v) {
                              final relative = prefs.customVoiceRelative;
                              if (relative == null) {
                                if (!mounted) return;
                                AppToast.error(
                                  context,
                                  l10n.alarmSettingsCustomVoiceMissing,
                                );
                                await context.push('/home/profile/voix');
                                return;
                              }
                            }
                            await prefs.setUseCustomVoice(v);
                            setState(() {});
                            await _afterChange();
                          },
                  ),
                  ListTile(
                    title: Text(l10n.profileVoixTitle),
                    subtitle: Text(l10n.profileVoixTileHint),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/home/profile/voix'),
                  ),
                ],
              ),
            ),
            if (!_exactOk) ...[
              const SizedBox(height: 16),
              PremiumCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.alarmSettingsExactTitle,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.alarmSettingsExactHint,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: tokens.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _requestExact,
                      child: Text(l10n.alarmSettingsExactCta),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            PremiumCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                title: Text(l10n.alarmHealthTitle),
                subtitle: Text(l10n.alarmHealthTileHint),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/home/profile/alarm-health'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
