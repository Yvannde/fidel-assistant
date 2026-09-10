import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/locale/locale_controller.dart';
import '../features/home/application/home_controller.dart';
import '../features/home/domain/dashboard_models.dart';
import 'alarm_prefs.dart';
import 'pending_prise_sync_queue.dart';
import 'reminder_alarm_service.dart';
import 'scheduled_dose.dart';

final reminderAlarmServiceProvider = Provider<ReminderAlarmService>((ref) {
  return ReminderAlarmService(ref.watch(sharedPreferencesProvider));
});

final alarmPrefsProvider = Provider<AlarmPrefs>((ref) {
  return AlarmPrefs(ref.watch(sharedPreferencesProvider));
});

final pendingPriseSyncQueueProvider = Provider<PendingPriseSyncQueue>((ref) {
  return PendingPriseSyncQueue(ref.watch(sharedPreferencesProvider));
});

/// Traite une réponse notif (foreground) : confirm / snooze / tap.
class ReminderActionDispatcher {
  ReminderActionDispatcher(this._container);

  final ProviderContainer _container;

  Future<void> handle(NotificationResponse response) async {
    final payload = parseReminderPayload(response.payload);
    final priseId = payload['priseId'] as String?;
    final kind = payload['kind'] as String?;
    final alarms = _container.read(reminderAlarmServiceProvider);
    final queue = _container.read(pendingPriseSyncQueueProvider);
    final repo = _container.read(homeRepositoryProvider);
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
      await queue.enqueueConfirm(priseId: priseId);
      try {
        await repo.confirmPrise(priseId);
        await queue.flush(repo);
      } catch (e) {
        debugPrint('ReminderAction confirm: $e');
      }
      try {
        await _container
            .read(homeControllerProvider.notifier)
            .load(secondary: false);
      } catch (_) {}
      return;
    }

    if (response.actionId == ReminderAlarmService.actionSnooze) {
      final when = DateTime.now().add(Duration(minutes: snoozeMin));
      await queue.enqueueReport(priseId: priseId, nouvelleHeure: when);
      try {
        await repo.reportPrise(priseId, when);
        await queue.flush(repo);
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
            .load(secondary: false);
      } catch (_) {}
    }
  }
}

/// Flush file + replanifie les alarmes (horizon J..J+2).
///
/// [dashboard] doit être passé par l’appelant : ne pas relire
/// [homeControllerProvider] depuis [HomeController] (cycle Riverpod).
///
/// Compatible [Ref.read] et [WidgetRef.read].
Future<void> syncRemindersFromHome(
  T Function<T>(ProviderListenable<T> provider) read,
  PatientDashboard dashboard,
) async {
  if (!dashboard.notificationsAccordees) return;

  final repo = read(homeRepositoryProvider);
  final queue = read(pendingPriseSyncQueueProvider);
  final alarms = read(reminderAlarmServiceProvider);

  try {
    await queue.flush(repo);
  } catch (_) {}

  try {
    final settings = await repo.fetchPatientSettings();
    await alarms.setDiscreet(settings.notificationsDiscretes);
  } catch (_) {}

  // Cache voix personnalisée pour le ring H0 (best-effort).
  try {
    final voix = await repo.fetchVoixRappel();
    final prefs = read(alarmPrefsProvider);
    if (voix.isPersonnalisee) {
      final bytes = await repo.downloadVoixRappelFichier();
      if (bytes != null && bytes.isNotEmpty) {
        await prefs.storeCustomVoiceBytes(
          bytes: bytes,
          filename: 'voix_rappel.m4a',
        );
      }
    }
  } catch (_) {}

  final today = homeDateOnly(DateTime.now());
  final doses = <ScheduledDose>[];

  void addPrises(List<PriseDuJour> prises) {
    for (final p in prises) {
      if (p.isPending) {
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
  }

  addPrises(dashboard.prisesAujourdhui);
  for (var i = 1; i <= 2; i++) {
    try {
      final list = await repo.listPrises(date: today.add(Duration(days: i)));
      addPrises(list);
    } catch (_) {}
  }

  final byId = <String, ScheduledDose>{};
  for (final d in doses) {
    byId[d.priseId] = d;
  }

  await alarms.rescheduleAll(byId.values.toList());
}
