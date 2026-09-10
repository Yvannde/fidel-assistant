import 'dart:convert';
import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../features/home/data/home_repository.dart';
import 'alarm_prefs.dart';
import 'pending_prise_sync_queue.dart';
import 'scheduled_dose.dart';

typedef ReminderNotificationCallback = void Function(NotificationResponse);

/// Rappels médicaments — préavis H0−Δ + alarme package H0 + marquage H0+5.
class ReminderAlarmService {
  ReminderAlarmService(this._prefs);

  static const preavisChannelId = 'fidel_med_preavis';
  static const preavisChannelName = 'Préavis médicaments';
  static const markChannelId = 'fidel_med_mark';
  static const markChannelName = 'Confirmation de prise';

  static const kindPreavis = 'preavis';
  static const kindAlarm = 'alarm';
  static const kindMark = 'mark';
  static const markDelay = Duration(minutes: 5);

  static const actionConfirm = 'prise_confirm';
  static const actionSnooze = 'prise_snooze';
  static const iosCategory = 'fidel_prise';
  static const _idsKey = 'reminder_notif_ids_v3';
  static const _alarmPkgIdsKey = 'reminder_alarm_pkg_ids_v1';
  static const _snapshotKey = 'reminder_dose_snapshot_v1';
  static const _doseCacheKey = 'reminder_doses_cache_v1';
  static const discreetPrefsKey = 'notifications_discretes';

  static const _labelConfirmFr = "J'ai pris";
  static const _labelSnoozeFr = 'Plus tard';
  static const _labelConfirmEn = 'Taken';
  static const _labelSnoozeEn = 'Later';
  static const _labelStopFr = 'Arrêter';
  static const _labelStopEn = 'Stop';

  final SharedPreferences _prefs;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  late final AlarmPrefs alarmPrefs = AlarmPrefs(_prefs);

  bool _ready = false;
  ReminderNotificationCallback? onResponse;

  bool get isReady => _ready;

  bool get _en => (_prefs.getString('fa_locale_code') ?? 'fr') == 'en';

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

  static int preavisNotificationId(String priseId) {
    final alarm = alarmNotificationId(priseId);
    var preavis = 0x7fffffff & (alarm ^ 0x11111111);
    if (preavis == 0 || preavis == alarm) {
      preavis = alarm == 1 ? 3 : 1;
    }
    final mark = markNotificationId(priseId);
    if (preavis == mark) {
      preavis = 0x7fffffff & (preavis ^ 0x22222222);
      if (preavis == 0 || preavis == alarm || preavis == mark) {
        preavis = alarm == 1 ? 4 : (alarm == 2 ? 4 : 2);
      }
    }
    return preavis;
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

  String _formatClock(DateTime when) {
    final local = when.isUtc ? when.toLocal() : when;
    return DateFormat.Hm(_en ? 'en' : 'fr').format(local);
  }

  String _medLabel(ScheduledDose dose) {
    final nom = dose.medicamentNom.trim();
    final dosage = dose.dosage.trim();
    if (nom.isEmpty) return dosage;
    if (dosage.isEmpty) return nom;
    return '$nom · $dosage';
  }

  ({String title, String body}) _copyFor({
    required ScheduledDose dose,
    required String kind,
  }) {
    final clock = _formatClock(dose.heurePrevue);
    final med = _medLabel(dose);
    final delta = alarmPrefs.preavisMinutes;

    if (kind == kindPreavis) {
      if (discreet) {
        return (
          title: _en ? 'Soon · $clock' : 'Bientôt · $clock',
          body: _en
              ? 'Reminder in $delta min ($clock).'
              : 'Rappel dans $delta min ($clock).',
        );
      }
      final label = med.isEmpty ? clock : med;
      return (
        title: _en ? 'In $delta min' : 'Dans $delta min',
        body: _en
            ? '$label — dose at $clock.'
            : '$label — prise à $clock.',
      );
    }

    if (kind == kindAlarm) {
      if (discreet) {
        return (
          title: 'Fidel · $clock',
          body: _en
              ? "It's time for your $clock reminder."
              : "C'est l'heure de ton rappel de $clock.",
        );
      }
      return (
        title: med.isEmpty ? (_en ? 'Dose · $clock' : 'Prise · $clock') : med,
        body: _en
            ? 'Time to take your dose (scheduled $clock).'
            : 'C’est l’heure de ta prise (prévue à $clock).',
      );
    }

    // mark
    if (discreet) {
      return (
        title: _en ? 'Confirm · $clock' : 'Confirmer · $clock',
        body: _en
            ? 'Did you complete your $clock reminder?'
            : 'As-tu bien fait ton rappel de $clock ?',
      );
    }
    return (
      title: med.isEmpty
          ? (_en ? 'Confirm dose · $clock' : 'Confirmer · $clock')
          : med,
      body: _en
          ? 'Confirm if you took this dose (scheduled $clock).'
          : 'Confirme si tu as pris cette dose (prévue à $clock).',
    );
  }

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
        preavisChannelId,
        preavisChannelName,
        description: 'Avertissement avant l’heure de prise',
        importance: Importance.high,
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

  Future<bool> hasExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    return Permission.scheduleExactAlarm.isGranted;
  }

  Future<void> cancelAllTracked() async {
    final ringingIds = _currentRingingIds();
    final ids = _trackedIds();
    for (final id in ids) {
      await _plugin.cancel(id);
    }
    await _prefs.setString(_idsKey, '[]');

    final alarmIds = _trackedAlarmPkgIds();
    for (final id in alarmIds) {
      if (ScheduledDose.shouldProtectRingingAlarm(
        alarmId: id,
        ringingIds: ringingIds,
      )) {
        continue;
      }
      try {
        await Alarm.stop(id);
      } catch (e) {
        debugPrint('ReminderAlarmService: Alarm.stop($id) failed: $e');
      }
    }
    // Conserve les ids encore en train de sonner.
    final kept = alarmIds
        .where(
          (id) => ScheduledDose.shouldProtectRingingAlarm(
            alarmId: id,
            ringingIds: ringingIds,
          ),
        )
        .toList();
    await _prefs.setString(_alarmPkgIdsKey, jsonEncode(kept));
    await _prefs.setString(_snapshotKey, '{}');
    await _prefs.setString(_doseCacheKey, '[]');
  }

  /// Cold start / après reboot : réarme depuis le cache local **sans** API home.
  ///
  /// [force] contourne le early-return fingerprint pour replanifier même si
  /// les signatures n’ont pas changé (AlarmManager / FLN peuvent avoir été
  /// perdus alors que le snapshot prefs est intact).
  Future<void> restoreFromLocalCache() async {
    if (!_ready) return;
    final cached = _loadDoseCache();
    if (cached.isEmpty) {
      debugPrint('ReminderAlarmService: restoreFromLocalCache empty');
      return;
    }
    final horizon = DateTime.now().subtract(markDelay);
    final future = cached
        .where((d) => d.heurePrevue.isAfter(horizon))
        .toList(growable: false);
    debugPrint(
      'ReminderAlarmService: restoreFromLocalCache '
      '${future.length}/${cached.length} doses',
    );
    await rescheduleAll(future, force: true);
  }

  /// Reschedule différentiel : ne touche que les prises ajoutées / modifiées /
  /// retirées, et ne stoppe jamais une alarme en cours de sonnerie.
  ///
  /// [force] : réarme toutes les doses non-ringing (boot / cold start).
  Future<void> rescheduleAll(
    List<ScheduledDose> doses, {
    bool force = false,
  }) async {
    if (!_ready) return;
    await ensureNotificationPermission();
    await ensureExactAlarmPermission();

    final audioKey = await alarmPrefs.resolveAudioPath();
    final preavisMin = alarmPrefs.preavisMinutes;
    final isDiscreet = discreet;

    final desiredSigs = <String, String>{};
    final desired = <String, ScheduledDose>{};
    for (final d in doses) {
      desired[d.priseId] = d;
      desiredSigs[d.priseId] = ScheduledDose.signature(
        dose: d,
        preavisMinutes: preavisMin,
        discreet: isDiscreet,
        audioKey: audioKey,
      );
    }

    // Toujours rafraîchir le cache doses (même si on skip la replanif).
    await _saveDoseCache(desired.values.toList());

    final previous = _loadSnapshot();
    if (!force &&
        ScheduledDose.globalFingerprint(previous) ==
            ScheduledDose.globalFingerprint(desiredSigs)) {
      debugPrint(
        'ReminderAlarmService: rescheduleAll skip (unchanged, '
        '${desiredSigs.length} doses)',
      );
      return;
    }

    final ringingIds = _currentRingingIds();
    final ids = _trackedIds();
    final alarmIds = _trackedAlarmPkgIds();
    final now = tz.TZDateTime.now(tz.local);

    var removed = 0;
    var updated = 0;
    var skipped = 0;
    var protectedRinging = 0;

    // Retraits.
    for (final priseId in previous.keys.toList()) {
      if (desired.containsKey(priseId)) continue;
      final alarmId = alarmNotificationId(priseId);
      if (ScheduledDose.shouldProtectRingingAlarm(
        alarmId: alarmId,
        ringingIds: ringingIds,
      )) {
        await _cancelFlnOnly(priseId, ids);
        protectedRinging++;
      } else {
        await _cancelPriseLocal(
          priseId,
          ids,
          alarmIds,
          stopAlarm: true,
        );
        removed++;
      }
    }

    // Ajouts / mises à jour.
    for (final entry in desired.entries) {
      final priseId = entry.key;
      final dose = entry.value;
      final sig = desiredSigs[priseId]!;
      final alarmId = alarmNotificationId(priseId);
      final preavisId = preavisNotificationId(priseId);
      final markId = markNotificationId(priseId);
      final unchanged = previous[priseId] == sig;
      final stillTracked = alarmIds.contains(alarmId) ||
          ids.contains(preavisId) ||
          ids.contains(markId);

      if (!force && unchanged && stillTracked) {
        skipped++;
        continue;
      }

      if (ScheduledDose.shouldProtectRingingAlarm(
        alarmId: alarmId,
        ringingIds: ringingIds,
      )) {
        // Ne pas re-set / stop H0 pendant le ring.
        if (!alarmIds.contains(alarmId)) alarmIds.add(alarmId);
        protectedRinging++;
        continue;
      }

      await _cancelPriseLocal(priseId, ids, alarmIds, stopAlarm: true);
      await _scheduleTriple(
        dose,
        now: now,
        track: ids,
        trackAlarms: alarmIds,
      );
      updated++;
    }

    await _prefs.setString(_idsKey, jsonEncode(ids));
    await _prefs.setString(_alarmPkgIdsKey, jsonEncode(alarmIds));
    await _saveSnapshot(desiredSigs);

    debugPrint(
      'ReminderAlarmService: rescheduleAll diff '
      'force=$force desired=${desired.length} updated=$updated '
      'removed=$removed skipped=$skipped protectRing=$protectedRinging '
      '(tz=${tz.local.name}, now=$now, Δ=$preavisMin)',
    );
  }

  /// Snooze : H0' = [dose.heurePrevue], préavis = H0'−Δ, mark = H0'+5.
  Future<void> scheduleOneShot(ScheduledDose dose) async {
    if (!_ready) return;
    await ensureExactAlarmPermission();
    final now = tz.TZDateTime.now(tz.local);
    final ids = _trackedIds();
    final alarmIds = _trackedAlarmPkgIds();
    await _cancelPriseLocal(dose.priseId, ids, alarmIds, stopAlarm: true);

    await _scheduleTriple(
      dose,
      now: now,
      track: ids,
      trackAlarms: alarmIds,
    );
    await _prefs.setString(_idsKey, jsonEncode(ids));
    await _prefs.setString(_alarmPkgIdsKey, jsonEncode(alarmIds));

    final snap = _loadSnapshot();
    snap[dose.priseId] = ScheduledDose.signature(
      dose: dose,
      preavisMinutes: alarmPrefs.preavisMinutes,
      discreet: discreet,
      audioKey: await alarmPrefs.resolveAudioPath(),
    );
    await _saveSnapshot(snap);
    final cache = _loadDoseCache();
    final next = [
      for (final d in cache)
        if (d.priseId != dose.priseId) d,
      dose,
    ];
    await _saveDoseCache(next);
  }

  Future<void> cancelPrise(String priseId) async {
    final ids = _trackedIds();
    final alarmIds = _trackedAlarmPkgIds();
    await _cancelPriseLocal(priseId, ids, alarmIds, stopAlarm: true);
    await _prefs.setString(_idsKey, jsonEncode(ids));
    await _prefs.setString(_alarmPkgIdsKey, jsonEncode(alarmIds));
    final snap = _loadSnapshot()..remove(priseId);
    await _saveSnapshot(snap);
    await _saveDoseCache(
      _loadDoseCache().where((d) => d.priseId != priseId).toList(),
    );
  }

  Future<void> _cancelFlnOnly(String priseId, List<int> ids) async {
    final markId = markNotificationId(priseId);
    final preavisId = preavisNotificationId(priseId);
    await _plugin.cancel(preavisId);
    await _plugin.cancel(markId);
    ids
      ..remove(preavisId)
      ..remove(markId);
  }

  Future<void> _cancelPriseLocal(
    String priseId,
    List<int> ids,
    List<int> alarmIds, {
    required bool stopAlarm,
  }) async {
    final alarmId = alarmNotificationId(priseId);
    final markId = markNotificationId(priseId);
    final preavisId = preavisNotificationId(priseId);
    await _plugin.cancel(preavisId);
    await _plugin.cancel(markId);
    ids
      ..remove(preavisId)
      ..remove(markId)
      ..remove(alarmId);
    alarmIds.remove(alarmId);
    if (stopAlarm) {
      try {
        await Alarm.stop(alarmId);
      } catch (e) {
        debugPrint('ReminderAlarmService: Alarm.stop($alarmId) failed: $e');
      }
    }
  }

  Set<int> _currentRingingIds() {
    try {
      return Alarm.ringing.value.alarms.map((a) => a.id).toSet();
    } catch (_) {
      return {};
    }
  }

  Map<String, String> _loadSnapshot() {
    final raw = _prefs.getString(_snapshotKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map(
        (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveSnapshot(Map<String, String> snapshot) async {
    await _prefs.setString(_snapshotKey, jsonEncode(snapshot));
  }

  List<ScheduledDose> _loadDoseCache() =>
      ScheduledDose.decodeList(_prefs.getString(_doseCacheKey));

  Future<void> _saveDoseCache(List<ScheduledDose> doses) async {
    await _prefs.setString(_doseCacheKey, ScheduledDose.encodeList(doses));
  }

  /// Annule préavis + alarme package + mark (isolate background).
  static Future<void> cancelBothForPrise(String priseId) async {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.cancel(preavisNotificationId(priseId));
    await plugin.cancel(markNotificationId(priseId));
    try {
      await Alarm.stop(alarmNotificationId(priseId));
    } catch (_) {}
  }

  static Future<void> cancelNotificationId(int id) async {
    await FlutterLocalNotificationsPlugin().cancel(id);
  }

  Future<({int preavis, int alarms, int marks})> _scheduleTriple(
    ScheduledDose dose, {
    required tz.TZDateTime now,
    required List<int> track,
    required List<int> trackAlarms,
  }) async {
    final h0 = tz.TZDateTime.from(dose.heurePrevue.toLocal(), tz.local);
    final preavisAt = h0.subtract(Duration(minutes: alarmPrefs.preavisMinutes));
    final markAt = h0.add(markDelay);
    var preavis = 0;
    var alarms = 0;
    var marks = 0;

    if (preavisAt.isAfter(now) && preavisAt.isBefore(h0)) {
      final ok = await _schedulePreavis(dose, when: preavisAt);
      if (ok) {
        track.add(preavisNotificationId(dose.priseId));
        preavis = 1;
      }
    }

    if (h0.isAfter(now)) {
      final ok = await _scheduleAlarmRing(dose, when: h0);
      if (ok) {
        trackAlarms.add(alarmNotificationId(dose.priseId));
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

    return (preavis: preavis, alarms: alarms, marks: marks);
  }

  Future<bool> _schedulePreavis(
    ScheduledDose dose, {
    required tz.TZDateTime when,
  }) async {
    final id = preavisNotificationId(dose.priseId);
    final copy = _copyFor(dose: dose, kind: kindPreavis);
    final payload = jsonEncode({
      'kind': kindPreavis,
      'priseId': dose.priseId,
      'medicamentNom': dose.medicamentNom,
      'dosage': dose.dosage,
    });

    try {
      await _plugin.zonedSchedule(
        id,
        copy.title,
        copy.body,
        when,
        NotificationDetails(
          android: AndroidNotificationDetails(
            preavisChannelId,
            preavisChannelName,
            channelDescription: 'Avertissement avant l’heure de prise',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
            playSound: true,
            enableVibration: true,
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
      debugPrint('ReminderAlarmService: preavis schedule failed $id: $e\n$st');
      return false;
    }
  }

  Future<bool> _scheduleAlarmRing(
    ScheduledDose dose, {
    required tz.TZDateTime when,
  }) async {
    final id = alarmNotificationId(dose.priseId);
    final copy = _copyFor(dose: dose, kind: kindAlarm);
    final audioPath = await alarmPrefs.resolveAudioPath();
    final payload = jsonEncode({
      'kind': kindAlarm,
      'priseId': dose.priseId,
      'medicamentNom': dose.medicamentNom,
      'dosage': dose.dosage,
      'heurePrevue': dose.heurePrevue.toIso8601String(),
    });

    try {
      final settings = AlarmSettings(
        id: id,
        dateTime: when.toLocal(),
        assetAudioPath: audioPath,
        loopAudio: true,
        vibrate: alarmPrefs.vibrate,
        warningNotificationOnKill: Platform.isIOS,
        androidFullScreenIntent: true,
        volumeSettings: VolumeSettings.fade(
          fadeDuration: const Duration(seconds: 4),
          volume: 0.95,
          volumeEnforced: true,
        ),
        notificationSettings: NotificationSettings(
          title: copy.title,
          body: copy.body,
          stopButton: _en ? _labelStopEn : _labelStopFr,
        ),
        payload: payload,
      );
      await Alarm.set(alarmSettings: settings);
      return true;
    } catch (e, st) {
      debugPrint('ReminderAlarmService: Alarm.set failed $id: $e\n$st');
      return false;
    }
  }

  Future<bool> _scheduleMark(
    ScheduledDose dose, {
    required tz.TZDateTime when,
  }) async {
    final id = markNotificationId(dose.priseId);
    final copy = _copyFor(dose: dose, kind: kindMark);
    final payload = jsonEncode({
      'kind': kindMark,
      'priseId': dose.priseId,
      'medicamentNom': dose.medicamentNom,
      'dosage': dose.dosage,
    });

    try {
      await _plugin.zonedSchedule(
        id,
        copy.title,
        copy.body,
        when,
        NotificationDetails(
          android: AndroidNotificationDetails(
            markChannelId,
            markChannelName,
            channelDescription: 'Confirmation de prise (H+5)',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
            actions: markAndroidActions(en: _en),
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
    return _decodeIdList(_prefs.getString(_idsKey));
  }

  List<int> _trackedAlarmPkgIds() {
    return _decodeIdList(_prefs.getString(_alarmPkgIdsKey));
  }

  List<int> _decodeIdList(String? raw) {
    if (raw == null || raw.isEmpty) {
      // Migration depuis v2 : nettoyer d’anciennes notifs FLN H0.
      if (raw == null) {
        final legacy = _prefs.getString('reminder_notif_ids_v2');
        if (legacy != null) {
          try {
            final decoded = jsonDecode(legacy);
            if (decoded is List) {
              for (final e in decoded) {
                _plugin.cancel((e as num).toInt());
              }
            }
          } catch (_) {}
          _prefs.remove('reminder_notif_ids_v2');
        }
      }
      return [];
    }
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
    if (action == null || action.isEmpty) return;

    await ReminderAlarmService.cancelBothForPrise(priseId);

    final prefs = await SharedPreferences.getInstance();
    final alarmPrefs = AlarmPrefs(prefs);
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
      final when =
          DateTime.now().add(Duration(minutes: alarmPrefs.snoozeMinutes));
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
