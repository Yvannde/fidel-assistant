import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'sos_aidant_alarm.dart';

/// Notif locale aidant pour observance (prise confirmée / absente).
class AidantObservanceNotif {
  static const channelId = 'fidel_sos_aidant';
  static const channelName = 'SOS patient';
  static const notificationIdBase = 92003000;

  static Future<void> show({
    required String kind,
    required String patientPrenom,
    required String medicament,
    required String heure,
    required String priseId,
    required String patientId,
  }) async {
    final plugin = FlutterLocalNotificationsPlugin();
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await plugin.initialize(initSettings);
    await SosAidantAlarm.ensureChannel(plugin);

    final confirmed = kind == 'prise_confirmee';
    final title = confirmed ? 'Prise confirmée' : 'Prise non confirmée';
    final body = confirmed
        ? '$patientPrenom a confirmé $medicament ($heure).'
        : 'Pas de confirmation pour $medicament de $patientPrenom ($heure).';

    final id = notificationIdBase + (priseId.hashCode.abs() % 1000);
    await plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Alertes des patients accompagnés',
          importance: Importance.high,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      payload: 'observance:$kind:$priseId:$patientId:$patientPrenom',
    );
    debugPrint('AidantObservanceNotif shown kind=$kind prise=$priseId');
  }
}
