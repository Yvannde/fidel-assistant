import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../features/home/domain/aidant_models.dart';

/// Alarme / notif haute priorité côté aidant quand un SOS arrive.
class SosAidantAlarm {
  static const channelId = 'fidel_sos_aidant';
  static const channelName = 'SOS patient';
  static const notificationIdBase = 92002000;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> _ensurePlugin() async {
    if (_initialized) return;
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(initSettings);
    await ensureChannel(_plugin);
    _initialized = true;
  }

  static Future<void> ensureChannel(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    const android = AndroidNotificationChannel(
      channelId,
      channelName,
      description: 'Alertes SOS des patients accompagnés',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(android);
  }

  static Future<void> show(ActiveSosAlert alert) async {
    await _ensurePlugin();

    final id = notificationIdBase + (alert.sosId.hashCode.abs() % 1000);
    await _plugin.show(
      id,
      'SOS — ${alert.patientPrenom}',
      'Ton proche a besoin d’aide. Ouvre Fidel pour acquitter.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Alertes SOS des patients accompagnés',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
          ongoing: true,
          autoCancel: false,
          playSound: true,
          onlyAlertOnce: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: 'sos:${alert.sosId}:${alert.patientId}:${alert.patientPrenom}',
    );
    debugPrint('SosAidantAlarm shown for ${alert.sosId}');
  }

  static Future<void> cancel(String sosId) async {
    await _ensurePlugin();
    final id = notificationIdBase + (sosId.hashCode.abs() % 1000);
    await _plugin.cancel(id);
  }
}

/// Parse payload `sos:id:patientId:prenom`.
ActiveSosAlert? parseSosPayload(String? payload) {
  if (payload == null || !payload.startsWith('sos:')) return null;
  final parts = payload.split(':');
  if (parts.length < 4) return null;
  return ActiveSosAlert(
    sosId: parts[1],
    patientId: parts[2],
    patientPrenom: parts.sublist(3).join(':'),
  );
}
