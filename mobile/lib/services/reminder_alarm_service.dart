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

/// Rappels médicaments — alarme H0 + notification de marquage H0+5.
class ReminderAlarmService {
  ReminderAlarmService(this._prefs);

  static const alarmChannelId = 'fidel_med_alarms';
  static const alarmChannelName = 'Alarmes médicaments';
  static const markChannelId = 'fidel_med_mark';
  static const markChannelName = 'Confirmation de prise';

  static const kindAlarm = 'alarm';
  static const kindMark = 'mark';
  static const markDelay = Duration(minutes: 5);

  static const actionConfirm = 'prise_confirm';
  static const actionSnooze = 'prise_snooze';
  static const iosCategory = 'fidel_prise';
  static const _idsKey = 'reminder_notif_ids_v2';
  static const discreetPrefsKey = 'notifications_discretes';

  static const _labelConfirmFr = "J'ai pris";
  static const _labelSnoozeFr = 'Plus tard';
  static const _labelConfirmEn = 'Taken';
  static const _labelSnoozeEn = 'Later';

  static const _alarmTitleFr = "C'est l'heure";
  static const _alarmTitleEn = "It's time";
  static const _markTitleFr = 'As-tu pris ton médicament ?';
  static const _markTitleEn = 'Did you take your medicine?';
  static const _titleDiscreetFr = 'Fidel';
  static const _titleDiscreetEn = 'Fidel';
  static const _alarmBodyDiscreetFr = "C'est l'heure de ton rappel.";
  static const _alarmBodyDiscreetEn = "It's time for your reminder.";
  static const _markBodyDiscreetFr = 'Peux-tu confirmer ton rappel ?';
  static const _markBodyDiscreetEn = 'Can you confirm your reminder?';

  final SharedPreferences _prefs;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  ReminderNotificationCallback? onResponse;

  bool get isReady => _ready;

  static int alarmNotificationId(String priseId) {
    var hash = 0;
    for (final cu in priseId.codeUnits) {
      hash = 0x7fffffff & (hash * 31 + cu);
    }
    return hash == 0 ? 1 : hash;
  }

  static int markNotificationId(String priseId) {
    final alarm = alarmNotificationId(priseId);
    final mark = 0x7fffffff & (alarm ^ 0x5f5f5f5f);
    return mark == 0 || mark == alarm ? (alarm == 1 ? 2 : 1) : mark;
  }

  /// @deprecated Prefer [alarmNotificationId] / [markNotificationId].
  static int notificationIdFor(String priseId) =>
      alarmNotificationId(priseId);

  static List<AndroidNotificationAction> markAndroidActions({
    required bool en,
  }) =>
      [
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
        alarmChannelId,
        alarmChannelName,
        description: 'Réveil à l’heure de prise Fidel',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        markChannelId,
        markChannelName,
        description: 'Confirmation de prise (H+5)',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
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

  /// Remplace toutes les alarmes / marks Fidel pour [doses] pending.
  Future<void> rescheduleAll(List<ScheduledDose> doses) async {
    if (!_ready) return;
    await ensureNotificationPermission();
    await ensureExactAlarmPermission();
    await cancelAllTracked();

    final now = tz.TZDateTime.now(tz.local);
    final scheduledIds = <int>[];
    var alarmCount = 0;
    var markCount = 0;

    for (final dose in doses) {
      final added = await _scheduleDual(dose, now: now, track: scheduledIds);
      alarmCount += added.alarms;
      markCount += added.marks;
    }

    await _prefs.setString(_idsKey, jsonEncode(scheduledIds));
    debugPrint(
      'ReminderAlarmService: scheduled alarms=$alarmCount marks=$markCount '
      'ids=${scheduledIds.length}/${doses.length} '
      '(tz=${tz.local.name}, now=$now)',
    );
  }

  /// Snooze : alarme à [dose.heurePrevue], mark à +5 min.
  Future<void> scheduleOneShot(ScheduledDose dose) async {
    if (!_ready) return;
    await ensureExactAlarmPermission();
    final now = tz.TZDateTime.now(tz.local);
    final ids = _trackedIds();
    // Remplace d’éventuelles notifs déjà trackées pour cette prise.
    final alarmId = alarmNotificationId(dose.priseId);
    final markId = markNotificationId(dose.priseId);
    await _plugin.cancel(alarmId);
    await _plugin.cancel(markId);
    ids.remove(alarmId);
    ids.remove(markId);

    await _scheduleDual(dose, now: now, track: ids);
    await _prefs.setString(_idsKey, jsonEncode(ids));
  }

  Future<void> cancelPrise(String priseId) async {
    final alarmId = alarmNotificationId(priseId);
    final markId = markNotificationId(priseId);
    await _plugin.cancel(alarmId);
    await _plugin.cancel(markId);
    final ids = _trackedIds()
      ..remove(alarmId)
      ..remove(markId);
    await _prefs.setString(_idsKey, jsonEncode(ids));
  }

  /// Annule les deux notifs d’une prise (isolate background inclus).
  static Future<void> cancelBothForPrise(String priseId) async {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.cancel(alarmNotificationId(priseId));
    await plugin.cancel(markNotificationId(priseId));
  }

  static Future<void> cancelNotificationId(int id) async {
    await FlutterLocalNotificationsPlugin().cancel(id);
  }

  Future<({int alarms, int marks})> _scheduleDual(
    ScheduledDose dose, {
    required tz.TZDateTime now,
    required List<int> track,
  }) async {
    final h0 = tz.TZDateTime.from(dose.heurePrevue.toLocal(), tz.local);
    final markAt = h0.add(markDelay);
    var alarms = 0;
    var marks = 0;

    if (h0.isAfter(now)) {
      final ok = await _scheduleAlarm(dose, when: h0);
      if (ok) {
        track.add(alarmNotificationId(dose.priseId));
        alarms = 1;
      }
    }

    if (markAt.isAfter(now)) {
      final ok = await _scheduleMark(dose, when: markAt);
      if (ok) {
        track.add(markNotificationId(dose.priseId));
        marks = 1;
      }
    }

    return (alarms: alarms, marks: marks);
  }

  Future<bool> _scheduleAlarm(
    ScheduledDose dose, {
    required tz.TZDateTime when,
  }) async {
    final en = (_prefs.getString('fa_locale_code') ?? 'fr') == 'en';
    final discreetMode = discreet;
    final id = alarmNotificationId(dose.priseId);
    final title = discreetMode
        ? (en ? _titleDiscreetEn : _titleDiscreetFr)
        : (en ? _alarmTitleEn : _alarmTitleFr);
    final body = discreetMode
        ? (en ? _alarmBodyDiscreetEn : _alarmBodyDiscreetFr)
        : '${dose.medicamentNom} · ${dose.dosage}'.trim();
    final payload = jsonEncode({
      'kind': kindAlarm,
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
            alarmChannelId,
            alarmChannelName,
            channelDescription: 'Réveil à l’heure de prise Fidel',
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.alarm,
            playSound: true,
            enableVibration: true,
            fullScreenIntent: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      return true;
    } catch (e, st) {
      debugPrint('ReminderAlarmService: alarm schedule failed $id: $e\n$st');
      return false;
    }
  }

  Future<bool> _scheduleMark(
    ScheduledDose dose, {
    required tz.TZDateTime when,
  }) async {
    final en = (_prefs.getString('fa_locale_code') ?? 'fr') == 'en';
    final discreetMode = discreet;
    final id = markNotificationId(dose.priseId);
    final title = discreetMode
        ? (en ? _titleDiscreetEn : _titleDiscreetFr)
        : (en ? _markTitleEn : _markTitleFr);
    final body = discreetMode
        ? (en ? _markBodyDiscreetEn : _markBodyDiscreetFr)
        : '${dose.medicamentNom} · ${dose.dosage}'.trim();
    final payload = jsonEncode({
      'kind': kindMark,
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
            markChannelId,
            markChannelName,
            channelDescription: 'Confirmation de prise (H+5)',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
            actions: markAndroidActions(en: en),
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
      return true;
    } catch (e, st) {
      debugPrint('ReminderAlarmService: mark schedule failed $id: $e\n$st');
      return false;
    }
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

    final action = response.actionId;
    // Tap alarme / mark sans action : rien à sync.
    if (action == null || action.isEmpty) return;

    await ReminderAlarmService.cancelBothForPrise(priseId);

    final prefs = await SharedPreferences.getInstance();
    final queue = PendingPriseSyncQueue(prefs);
    final repo =
        HomeRepository(apiClient: ApiClient(tokenStorage: TokenStorage()));

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
