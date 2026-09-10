import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../features/home/data/home_repository.dart';
import 'pending_prise_sync_queue.dart';
import 'scheduled_dose.dart';

typedef ReminderNotificationCallback = void Function(NotificationResponse);

/// Rappels médicaments — notifications locales exactes.
class ReminderAlarmService {
  ReminderAlarmService(this._prefs);

  static const channelId = 'fidel_med_reminders';
  static const channelName = 'Rappels médicaments';
  static const actionConfirm = 'prise_confirm';
  static const actionSnooze = 'prise_snooze';
  static const iosCategory = 'fidel_prise';
  static const _idsKey = 'reminder_notif_ids_v1';
  static const discreetPrefsKey = 'notifications_discretes';

  static const _labelConfirmFr = "J'ai pris";
  static const _labelSnoozeFr = 'Plus tard';
  static const _titleFr = 'Rappel médicament';
  static const _titleDiscreetFr = 'Fidel';
  static const _bodyDiscreetFr = "C'est l'heure de ton rappel.";
  static const _labelConfirmEn = 'Taken';
  static const _labelSnoozeEn = 'Later';
  static const _titleEn = 'Medicine reminder';
  static const _titleDiscreetEn = 'Fidel';
  static const _bodyDiscreetEn = "It's time for your reminder.";

  final SharedPreferences _prefs;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  ReminderNotificationCallback? onResponse;

  bool get isReady => _ready;

  static int notificationIdFor(String priseId) {
    var hash = 0;
    for (final cu in priseId.codeUnits) {
      hash = 0x7fffffff & (hash * 31 + cu);
    }
    return hash == 0 ? 1 : hash;
  }

  /// Actions Android : ouvre l’app + retire la notif dès le tap.
  static List<AndroidNotificationAction> androidActions({required bool en}) => [
        AndroidNotificationAction(
          actionConfirm,
          en ? _labelConfirmEn : _labelConfirmFr,
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          actionSnooze,
          en ? _labelSnoozeEn : _labelSnoozeFr,
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ];

  Future<void> init({ReminderNotificationCallback? onResponse}) async {
    this.onResponse = onResponse;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          iosCategory,
          actions: [
            DarwinNotificationAction.plain(actionConfirm, _labelConfirmFr),
            DarwinNotificationAction.plain(actionSnooze, _labelSnoozeFr),
          ],
        ),
      ],
    );

    await _plugin.initialize(
      InitializationSettings(android: androidInit, iOS: darwinInit),
      onDidReceiveNotificationResponse: (r) => this.onResponse?.call(r),
      onDidReceiveBackgroundNotificationResponse: reminderBackgroundHandler,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: 'Rappels de prises Fidel',
        importance: Importance.high,
      ),
    );

    _ready = true;
  }

  Future<void> setDiscreet(bool value) async {
    await _prefs.setBool(discreetPrefsKey, value);
  }

  bool get discreet => _prefs.getBool(discreetPrefsKey) ?? false;

  Future<bool> ensureNotificationPermission() async {
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await android?.areNotificationsEnabled();
      if (enabled == false) {
        await android?.requestNotificationsPermission();
      }
    } else if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    }
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    final next = await Permission.notification.request();
    return next.isGranted;
  }

  Future<bool> ensureExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.scheduleExactAlarm.status;
    if (status.isGranted) return true;
    final next = await Permission.scheduleExactAlarm.request();
    return next.isGranted;
  }

  Future<void> cancelAllTracked() async {
    final ids = _trackedIds();
    for (final id in ids) {
      await _plugin.cancel(id);
    }
    await _prefs.setString(_idsKey, '[]');
  }

  /// Remplace toutes les alarmes Fidel par [doses] futures pending.
  Future<void> rescheduleAll(List<ScheduledDose> doses) async {
    if (!_ready) return;
    await ensureNotificationPermission();
    await ensureExactAlarmPermission();
    await cancelAllTracked();

    final now = tz.TZDateTime.now(tz.local);
    final en = (_prefs.getString('fa_locale_code') ?? 'fr') == 'en';
    final discreetMode = discreet;
    final scheduledIds = <int>[];

    for (final dose in doses) {
      final when = tz.TZDateTime.from(dose.heurePrevue.toLocal(), tz.local);
      if (!when.isAfter(now)) continue;

      final id = notificationIdFor(dose.priseId);
      final title = discreetMode
          ? (en ? _titleDiscreetEn : _titleDiscreetFr)
          : (en ? _titleEn : _titleFr);
      final body = discreetMode
          ? (en ? _bodyDiscreetEn : _bodyDiscreetFr)
          : '${dose.medicamentNom} · ${dose.dosage}'.trim();

      final payload = jsonEncode({
        'priseId': dose.priseId,
        'medicamentNom': dose.medicamentNom,
        'dosage': dose.dosage,
      });

      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          when,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              channelName,
              channelDescription: 'Rappels de prises Fidel',
              importance: Importance.high,
              priority: Priority.high,
              category: AndroidNotificationCategory.reminder,
              actions: androidActions(en: en),
            ),
            iOS: const DarwinNotificationDetails(
              categoryIdentifier: iosCategory,
              presentAlert: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
        scheduledIds.add(id);
      } catch (e, st) {
        debugPrint('ReminderAlarmService: schedule failed $id: $e\n$st');
      }
    }

    await _prefs.setString(_idsKey, jsonEncode(scheduledIds));
    debugPrint(
      'ReminderAlarmService: scheduled ${scheduledIds.length}/${doses.length} '
      '(tz=${tz.local.name}, now=$now)',
    );
  }

  /// Planifie uniquement un snooze sans tout annuler.
  Future<void> scheduleOneShot(ScheduledDose dose) async {
    if (!_ready) return;
    await ensureExactAlarmPermission();
    final when = tz.TZDateTime.from(dose.heurePrevue.toLocal(), tz.local);
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;

    final en = (_prefs.getString('fa_locale_code') ?? 'fr') == 'en';
    final discreetMode = discreet;
    final id = notificationIdFor(dose.priseId);
    final title = discreetMode
        ? (en ? _titleDiscreetEn : _titleDiscreetFr)
        : (en ? _titleEn : _titleFr);
    final body = discreetMode
        ? (en ? _bodyDiscreetEn : _bodyDiscreetFr)
        : '${dose.medicamentNom} · ${dose.dosage}'.trim();
    final payload = jsonEncode({
      'priseId': dose.priseId,
      'medicamentNom': dose.medicamentNom,
      'dosage': dose.dosage,
    });

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Rappels de prises Fidel',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          actions: androidActions(en: en),
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: iosCategory,
          presentAlert: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    final ids = _trackedIds();
    if (!ids.contains(id)) {
      ids.add(id);
      await _prefs.setString(_idsKey, jsonEncode(ids));
    }
  }

  Future<void> cancelPrise(String priseId) async {
    final id = notificationIdFor(priseId);
    await _plugin.cancel(id);
    final ids = _trackedIds()..remove(id);
    await _prefs.setString(_idsKey, jsonEncode(ids));
  }

  /// Annule une notif même hors du service initialisé (isolate background).
  static Future<void> cancelNotificationId(int id) async {
    await FlutterLocalNotificationsPlugin().cancel(id);
  }

  List<int> _trackedIds() {
    final raw = _prefs.getString(_idsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.map((e) => (e as num).toInt()).toList();
    } catch (_) {
      return [];
    }
  }
}

Map<String, dynamic> parseReminderPayload(String? raw) {
  if (raw == null || raw.isEmpty) return {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {}
  return {};
}

/// Handler background — top-level + async pour laisser finir le travail.
@pragma('vm:entry-point')
Future<void> reminderBackgroundHandler(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final payload = parseReminderPayload(response.payload);
    final priseId = payload['priseId'] as String?;
    if (priseId == null || priseId.isEmpty) return;

    final notifId = response.id ?? ReminderAlarmService.notificationIdFor(priseId);
    await ReminderAlarmService.cancelNotificationId(notifId);

    final prefs = await SharedPreferences.getInstance();
    final queue = PendingPriseSyncQueue(prefs);
    final repo = HomeRepository(apiClient: ApiClient(tokenStorage: TokenStorage()));

    final action = response.actionId;
    if (action == ReminderAlarmService.actionConfirm) {
      await queue.enqueueConfirm(priseId: priseId);
      try {
        await repo.confirmPrise(priseId);
        await queue.flush(repo);
      } catch (e) {
        debugPrint('reminderBackgroundHandler confirm: $e');
      }
      return;
    }
    if (action == ReminderAlarmService.actionSnooze) {
      final when = DateTime.now().add(const Duration(minutes: 15));
      await queue.enqueueReport(priseId: priseId, nouvelleHeure: when);
      try {
        await repo.reportPrise(priseId, when);
        await queue.flush(repo);
      } catch (e) {
        debugPrint('reminderBackgroundHandler snooze: $e');
      }
      final alarms = ReminderAlarmService(prefs);
      await alarms.init();
      await alarms.scheduleOneShot(
        ScheduledDose(
          priseId: priseId,
          medicamentNom: payload['medicamentNom'] as String? ?? '',
          dosage: payload['dosage'] as String? ?? '',
          heurePrevue: when,
        ),
      );
    }
  } catch (e, st) {
    debugPrint('reminderBackgroundHandler: $e\n$st');
  }
}
