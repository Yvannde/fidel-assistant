import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/database/providers.dart';
import '../core/locale/locale_controller.dart';
import '../features/home/application/home_controller.dart';
import '../features/home/data/home_repository.dart';
import '../features/home/domain/dashboard_models.dart';
import 'alarm_prefs.dart';
import 'reminder_alarm_service.dart';
import 'reminder_sync_perf.dart';
import 'scheduled_dose.dart';
import 'sync_engine.dart';

final reminderAlarmServiceProvider = Provider<ReminderAlarmService>((ref) {
  return ReminderAlarmService(ref.watch(sharedPreferencesProvider));
});

final alarmPrefsProvider = Provider<AlarmPrefs>((ref) {
  return AlarmPrefs(ref.watch(sharedPreferencesProvider));
});

const _syncGateKey = 'reminder_sync_gate_v1';
const _voixMetaPrefsKey = 'reminder_voix_meta_v1';

const _syncGateKey = 'reminder_sync_gate_v1';
const _voixMetaPrefsKey = 'reminder_voix_meta_v1';

/// Traite une réponse notif (foreground) : confirm / snooze / tap.
class ReminderActionDispatcher {
  ReminderActionDispatcher(this._container);

  final ProviderContainer _container;

  Future<void> handle(NotificationResponse response) async {
    final payload = parseReminderPayload(response.payload);
    final priseId = payload['priseId'] as String?;
    final kind = payload['kind'] as String?;
    final alarms = _container.read(reminderAlarmServiceProvider);
    final engine = _container.read(syncEngineProvider);
    final snoozeMin = _container.read(alarmPrefsProvider).snoozeMinutes;

    debugPrint(
      'ReminderAction: actionId=${response.actionId} kind=$kind '
      'type=${response.notificationResponseType} priseId=$priseId',
    );

    if (response.actionId == null || response.actionId!.isEmpty) {
      if (response.notificationResponseType ==
          NotificationResponseType.selectedNotification) {
        _container.read(homeTabIndexProvider.notifier).state = 0;
      }
      return;
    }

    if (priseId == null || priseId.isEmpty) return;

    await alarms.cancelPrise(priseId);

    if (response.actionId == ReminderAlarmService.actionConfirm) {
      await engine.enqueueConfirm(priseId: priseId);
      try {
        await engine.flush(force: true);
      } catch (e) {
        debugPrint('ReminderAction confirm: $e');
      }
      try {
        await _container
            .read(homeControllerProvider.notifier)
            .reloadProjection();
      } catch (_) {}
      return;
    }

    if (response.actionId == ReminderAlarmService.actionSnooze) {
      final when = DateTime.now().add(Duration(minutes: snoozeMin));
      await engine.enqueueReport(priseId: priseId, nouvelleHeure: when);
      try {
        await engine.flush(force: true);
      } catch (e) {
        debugPrint('ReminderAction snooze: $e');
      }
      await alarms.scheduleOneShot(
        ScheduledDose(
          priseId: priseId,
          medicamentNom: payload['medicamentNom'] as String? ?? '',
          dosage: payload['dosage'] as String? ?? '',
          heurePrevue: when,
        ),
      );
      try {
        await _container
            .read(homeControllerProvider.notifier)
            .reloadProjection();
      } catch (_) {}
    }
  }
}

/// Flush file + replanifie les alarmes (horizon [ReminderSyncPerf.scheduleHorizon]).
///
/// [dashboard] doit être passé par l’appelant : ne pas relire
/// [homeControllerProvider] depuis [HomeController] (cycle Riverpod).
///
/// Compatible [Ref.read] et [WidgetRef.read].
///
/// [force] : ignore le skip fingerprint (réglages alarme / tests).
Future<void> syncRemindersFromHome(
  T Function<T>(ProviderListenable<T> provider) read,
  PatientDashboard dashboard, {
  bool force = false,
}) async {
  if (!dashboard.notificationsAccordees) return;

  final repo = read(homeRepositoryProvider);
  final engine = read(syncEngineProvider);
  final alarms = read(reminderAlarmServiceProvider);
  final alarmPrefs = read(alarmPrefsProvider);
  final prefs = read(sharedPreferencesProvider);
  final db = read(appDatabaseProvider);

  try {
    await engine.flush();
  } catch (_) {}

  final dashFp = ReminderSyncPerf.dashboardPendingFingerprint(
    dashboard.prisesAujourdhui,
  );
  final gate = ReminderSyncPerf.syncGateKey(
    dashboardFingerprint: dashFp,
    preavisMinutes: alarmPrefs.preavisMinutes,
    discreet: alarms.discreet,
    useCustomVoice: alarmPrefs.useCustomVoice,
    customVoiceExt: alarmPrefs.customVoiceExt,
  );

  if (!force && prefs.getString(_syncGateKey) == gate) {
    debugPrint('syncRemindersFromHome skip (unchanged gate)');
    return;
  }

  try {
    final settings = await repo.fetchPatientSettings();
    await alarms.setDiscreet(settings.notificationsDiscretes);
  } catch (_) {}

  await _refreshVoixCacheIfNeeded(
    repo: repo,
    prefs: prefs,
    alarmPrefs: alarmPrefs,
  );

  final now = DateTime.now();
  final today = homeDateOnly(now);
  final doses = <ScheduledDose>[];

  void addPrises(List<PriseDuJour> prises) {
    for (final p in prises) {
      if (!p.isPending) continue;
      if (!ReminderSyncPerf.isWithinHorizon(p.heurePrevue, now)) continue;
      doses.add(
        ScheduledDose(
          priseId: p.id,
          medicamentNom: p.medicamentNom,
          dosage: p.dosage,
          heurePrevue: p.heurePrevue,
        ),
      );
    }
  }

  addPrises(dashboard.prisesAujourdhui);
  try {
    await db.upsertPrises(dashboard.prisesAujourdhui);
  } catch (_) {}

  final extraDays = ReminderSyncPerf.extraDaysToFetch(now);
  for (var i = 1; i <= extraDays; i++) {
    try {
      final list = await repo.listPrises(date: today.add(Duration(days: i)));
      try {
        await db.upsertPrises(list);
      } catch (_) {}
      addPrises(list);
    } catch (_) {}
  }

  final byId = <String, ScheduledDose>{};
  for (final d in doses) {
    byId[d.priseId] = d;
  }

  await alarms.rescheduleAll(byId.values.toList());

  // Gate après sync réussi (prefs discreet peuvent avoir changé).
  final gateAfter = ReminderSyncPerf.syncGateKey(
    dashboardFingerprint: dashFp,
    preavisMinutes: alarmPrefs.preavisMinutes,
    discreet: alarms.discreet,
    useCustomVoice: alarmPrefs.useCustomVoice,
    customVoiceExt: alarmPrefs.customVoiceExt,
  );
  await prefs.setString(_syncGateKey, gateAfter);
}

Future<void> _refreshVoixCacheIfNeeded({
  required HomeRepository repo,
  required SharedPreferences prefs,
  required AlarmPrefs alarmPrefs,
}) async {
  try {
    final voix = await repo.fetchVoixRappel();
    final meta = ReminderSyncPerf.voixMetaKey(
      id: voix.id,
      fichierAudioUrl: voix.fichierAudioUrl,
      isPersonnalisee: voix.isPersonnalisee,
    );
    final last = prefs.getString(_voixMetaPrefsKey);
    if (!voix.isPersonnalisee) {
      if (last != meta) await prefs.setString(_voixMetaPrefsKey, meta);
      return;
    }

    final audioPath = await alarmPrefs.resolveAudioPath();
    final hasLocalCustom = audioPath != AlarmPrefs.defaultAssetAudio;
    if (last == meta && hasLocalCustom) {
      debugPrint('syncRemindersFromHome: voix cache hit');
      return;
    }

    final bytes = await repo.downloadVoixRappelFichier();
    if (bytes != null && bytes.isNotEmpty) {
      await alarmPrefs.storeCustomVoiceBytes(
        bytes: bytes,
        filename: 'voix_rappel.m4a',
      );
      await prefs.setString(_voixMetaPrefsKey, meta);
    }
  } catch (_) {}
}
