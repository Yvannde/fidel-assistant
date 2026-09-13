import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../features/home/domain/dashboard_models.dart';

/// Rappel check-in quotidien local — 15:00, 4 actions (malheureux → heureux).
///
/// Android : notif custom RemoteViews (4 icônes vectorielles) — les actions
/// système sont limitées à 3 boutons texte.
/// iOS : actions texte (pas d’icône custom fiable).
class CheckInReminderService {
  CheckInReminderService(this._prefs, this._plugin);

  static const channelId = 'fidel_check_in_daily';
  static const channelName = 'Check-in quotidien';
  static const kind = 'check_in_daily';
  static const iosCategory = 'fidel_check_in';
  static const notificationId = 91001500;
  static const debugNotificationId = 91001501;
  static const hour = 15;
  static const minute = 0;

  static const actionTresMal = 'check_in_tres_mal';
  static const actionPasTop = 'check_in_pas_top';
  static const actionCaVa = 'check_in_ca_va';
  static const actionSuper = 'check_in_super';

  static const _nativeChannelName = 'cm.fidel.assistant/check_in_notif';
  static const _scheduledKey = 'check_in_reminder_scheduled_v1';
  static const _debugFireDayKey = 'check_in_debug_fire_day_v5';

  static const MethodChannel _native = MethodChannel(_nativeChannelName);

  final SharedPreferences _prefs;
  final FlutterLocalNotificationsPlugin _plugin;

  /// Callback quand l’utilisateur tape une icône mood (Android custom notif).
  static void Function(String actionId)? onNativeAction;

  bool get _en => (_prefs.getString('fa_locale_code') ?? 'fr') == 'en';

  static String? statutFromAction(String? actionId) {
    return switch (actionId) {
      actionTresMal => 'tres_mal',
      actionPasTop => 'pas_top',
      actionCaVa => 'ca_va',
      actionSuper => 'super',
      _ => null,
    };
  }

  static String payloadJson() => jsonEncode({'kind': kind});

  /// À appeler une fois au démarrage (main) pour recevoir les clics Android.
  static void bindNativeActionHandler(void Function(String actionId) handler) {
    onNativeAction = handler;
    _native.setMethodCallHandler((call) async {
      if (call.method == 'onAction') {
        final actionId = call.arguments as String?;
        if (actionId != null) {
          onNativeAction?.call(actionId);
        }
      }
    });
  }

  static Future<String?> consumePendingNativeAction() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _native.invokeMethod<String>('consumePendingAction');
    } catch (_) {
      return null;
    }
  }

  /// Titres accessibilité iOS (pas d’icône custom fiable sur actions notif).
  static List<DarwinNotificationAction> iosActions({required bool en}) => [
        DarwinNotificationAction.plain(
          actionTresMal,
          en ? 'Very bad' : 'Très mal',
        ),
        DarwinNotificationAction.plain(
          actionPasTop,
          en ? 'Not great' : 'Pas top',
        ),
        DarwinNotificationAction.plain(
          actionCaVa,
          en ? 'Okay' : 'Ça va',
        ),
        DarwinNotificationAction.plain(
          actionSuper,
          en ? 'Great' : 'Super',
        ),
      ];

  ({String title, String body}) get _copy => (
        title: _en
            ? 'How are you feeling today?'
            : 'Comment tu te sens aujourd’hui ?',
        body: _en
            ? 'One tap, four choices — helps keep your follow-up on track.'
            : 'Un geste, quatre choix — ça aide à suivre ton suivi.',
      );

  NotificationDetails get _iosDetails => NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          categoryIdentifier: iosCategory,
        ),
      );

  Future<void> ensureChannel() async {
    if (Platform.isAndroid) return;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: 'Rappel local « comment tu te sens » à 15 h',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  /// Affiche la notif tout de suite (test / debug).
  Future<void> showNow() async {
    final copy = _copy;
    if (Platform.isAndroid) {
      await _native.invokeMethod<bool>('show', {
        'title': copy.title,
        'body': copy.body,
        'id': debugNotificationId,
      });
      debugPrint('CheckInReminderService: showNow() native Android fired');
      return;
    }
    await ensureChannel();
    await _plugin.show(
      debugNotificationId,
      copy.title,
      copy.body,
      _iosDetails,
      payload: payloadJson(),
    );
    debugPrint('CheckInReminderService: showNow() fired');
  }

  /// Planifie le rappel quotidien si maladie configurée et pas encore répondu.
  Future<void> syncSchedule({
    required bool hasMaladie,
    required bool alreadyCheckedInToday,
  }) async {
    debugPrint(
      'CheckInReminderService.syncSchedule '
      'hasMaladie=$hasMaladie alreadyCheckedIn=$alreadyCheckedInToday',
    );
    if (!hasMaladie) {
      await cancel();
      return;
    }
    if (alreadyCheckedInToday) {
      await cancelPendingToday();
      await _scheduleDaily(skipIfSameDayPast: true);
      return;
    }
    await _scheduleDaily(skipIfSameDayPast: false);

    // En debug : une notif dans ~20 s pour valider sans attendre 15 h.
    if (kDebugMode) {
      await _maybeScheduleDebugSoon();
    }
  }

  Future<void> cancel() async {
    if (Platform.isAndroid) {
      try {
        await _native.invokeMethod<bool>('cancelSchedule');
      } catch (_) {}
      await _prefs.remove(_scheduledKey);
      return;
    }
    try {
      await _plugin.cancel(notificationId);
      await _plugin.cancel(debugNotificationId);
    } catch (_) {}
    await _prefs.remove(_scheduledKey);
  }

  /// Annule l’occurrence en attente (après réponse) sans retirer le besoin demain.
  Future<void> cancelPendingToday() async {
    if (Platform.isAndroid) {
      try {
        await _native.invokeMethod<bool>('cancel', {'id': notificationId});
        await _native.invokeMethod<bool>('cancel', {'id': debugNotificationId});
      } catch (_) {}
      return;
    }
    try {
      await _plugin.cancel(notificationId);
      await _plugin.cancel(debugNotificationId);
    } catch (_) {}
  }

  Future<void> _scheduleDaily({required bool skipIfSameDayPast}) async {
    final copy = _copy;
    if (Platform.isAndroid) {
      try {
        await _native.invokeMethod<bool>('scheduleDaily', {
          'title': copy.title,
          'body': copy.body,
          'hour': hour,
          'minute': minute,
          'skipIfSameDayPast': skipIfSameDayPast,
        });
        final now = DateTime.now();
        var when = DateTime(now.year, now.month, now.day, hour, minute);
        if (when.isBefore(now) || skipIfSameDayPast) {
          when = when.add(const Duration(days: 1));
        }
        await _prefs.setString(_scheduledKey, when.toIso8601String());
        debugPrint('CheckInReminderService: scheduled native daily at $when');
      } catch (e, st) {
        debugPrint('CheckInReminderService: native schedule failed: $e\n$st');
      }
      return;
    }

    await ensureChannel();
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (when.isBefore(now) || skipIfSameDayPast) {
      when = when.add(const Duration(days: 1));
    }

    try {
      await _plugin.cancel(notificationId);
      await _plugin.zonedSchedule(
        notificationId,
        copy.title,
        copy.body,
        when,
        _iosDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payloadJson(),
      );
      await _prefs.setString(_scheduledKey, when.toIso8601String());
      debugPrint('CheckInReminderService: scheduled daily at $when');
    } catch (e, st) {
      debugPrint('CheckInReminderService: schedule failed: $e\n$st');
      try {
        await _plugin.zonedSchedule(
          notificationId,
          copy.title,
          copy.body,
          when,
          _iosDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payloadJson(),
        );
        await _prefs.setString(_scheduledKey, when.toIso8601String());
        debugPrint('CheckInReminderService: scheduled (inexact) at $when');
      } catch (e2, st2) {
        debugPrint('CheckInReminderService: inexact also failed: $e2\n$st2');
      }
    }
  }

  Future<void> _maybeScheduleDebugSoon() async {
    final now = DateTime.now();
    final dayKey =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    if (_prefs.getString(_debugFireDayKey) == dayKey) {
      debugPrint('CheckInReminderService: debug fire already done for $dayKey');
      return;
    }

    await _prefs.setString(_debugFireDayKey, dayKey);
    await showNow();
  }

  static bool isCheckInPayload(Map<String, dynamic> payload) =>
      payload['kind'] == kind;

  static bool isValidStatut(String statut) =>
      CheckInEntry.levels.contains(statut);
}
