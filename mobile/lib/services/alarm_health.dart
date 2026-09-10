import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// Checks OS-level settings that gate medication alarms (Android OEM focus).
class AlarmHealthStatus {
  const AlarmHealthStatus({
    required this.notifications,
    required this.exactAlarm,
    required this.batteryExempt,
    required this.fullScreenIntent,
    required this.manufacturer,
    required this.brand,
    required this.sdkInt,
    required this.oemAutostartLikelyNeeded,
  });

  final bool notifications;
  final bool exactAlarm;
  final bool batteryExempt;
  final bool fullScreenIntent;
  final String manufacturer;
  final String brand;
  final int sdkInt;
  final bool oemAutostartLikelyNeeded;

  bool get allCoreOk =>
      notifications && exactAlarm && batteryExempt && fullScreenIntent;

  /// Pure helper for OEM tip key (testable without channel).
  static String oemTipKey(String manufacturer, String brand) {
    final m = manufacturer.toLowerCase();
    final b = brand.toLowerCase();
    bool has(String k) => m.contains(k) || b.contains(k);
    if (has('xiaomi') || has('redmi') || has('poco')) return 'xiaomi';
    if (has('huawei') || has('honor')) return 'huawei';
    if (has('samsung')) return 'samsung';
    if (has('oppo') || has('realme')) return 'oppo';
    if (has('oneplus')) return 'oneplus';
    if (has('vivo') || has('iqoo')) return 'vivo';
    if (has('tecno') || has('infinix') || has('itel') || has('transsion')) {
      return 'transsion';
    }
    if (has('asus')) return 'asus';
    return 'generic';
  }

  String get tipKey => oemTipKey(manufacturer, brand);

  factory AlarmHealthStatus.fromMap(Map<dynamic, dynamic> map) {
    return AlarmHealthStatus(
      notifications: map['notifications'] == true,
      exactAlarm: map['exactAlarm'] == true,
      batteryExempt: map['batteryExempt'] == true,
      fullScreenIntent: map['fullScreenIntent'] == true,
      manufacturer: '${map['manufacturer'] ?? ''}',
      brand: '${map['brand'] ?? ''}',
      sdkInt: (map['sdkInt'] as num?)?.toInt() ?? 0,
      oemAutostartLikelyNeeded: map['oemAutostartLikelyNeeded'] == true,
    );
  }

  static const iosOk = AlarmHealthStatus(
    notifications: true,
    exactAlarm: true,
    batteryExempt: true,
    fullScreenIntent: true,
    manufacturer: 'Apple',
    brand: 'Apple',
    sdkInt: 0,
    oemAutostartLikelyNeeded: false,
  );
}

enum AlarmHealthFix {
  notifications,
  exactAlarm,
  batteryExempt,
  fullScreenIntent,
  oemAutostart,
  appDetails,
}

class AlarmHealthService {
  AlarmHealthService({MethodChannel? channel})
      : _channel = channel ??
            const MethodChannel('cm.fidel.assistant/alarm_health');

  final MethodChannel _channel;

  Future<AlarmHealthStatus> readStatus() async {
    if (kIsWeb || !Platform.isAndroid) {
      final notif = await Permission.notification.status;
      return AlarmHealthStatus(
        notifications: notif.isGranted,
        exactAlarm: true,
        batteryExempt: true,
        fullScreenIntent: true,
        manufacturer: Platform.isIOS ? 'Apple' : Platform.operatingSystem,
        brand: Platform.isIOS ? 'Apple' : Platform.operatingSystem,
        sdkInt: 0,
        oemAutostartLikelyNeeded: false,
      );
    }
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>('getStatus');
      if (raw == null) return AlarmHealthStatus.iosOk;
      return AlarmHealthStatus.fromMap(raw);
    } on PlatformException {
      return _fallbackStatus();
    } on MissingPluginException {
      return _fallbackStatus();
    }
  }

  Future<AlarmHealthStatus> _fallbackStatus() async {
    final notif = await Permission.notification.isGranted;
    final exact = await Permission.scheduleExactAlarm.isGranted;
    final batt = await Permission.ignoreBatteryOptimizations.isGranted;
    return AlarmHealthStatus(
      notifications: notif,
      exactAlarm: exact,
      batteryExempt: batt,
      fullScreenIntent: true,
      manufacturer: '',
      brand: '',
      sdkInt: 0,
      oemAutostartLikelyNeeded: false,
    );
  }

  Future<bool> fix(AlarmHealthFix kind) async {
    if (kIsWeb) return false;
    if (!Platform.isAndroid) {
      if (kind == AlarmHealthFix.notifications) {
        final next = await Permission.notification.request();
        if (!next.isGranted) return openAppSettings();
        return true;
      }
      return openAppSettings();
    }

    switch (kind) {
      case AlarmHealthFix.notifications:
        final next = await Permission.notification.request();
        if (next.isGranted) return true;
        return _invoke('openAppDetailsSettings');
      case AlarmHealthFix.exactAlarm:
        final next = await Permission.scheduleExactAlarm.request();
        if (next.isGranted) return true;
        return _invoke('openExactAlarmSettings');
      case AlarmHealthFix.batteryExempt:
        final next = await Permission.ignoreBatteryOptimizations.request();
        if (next.isGranted) return true;
        return _invoke('openBatteryExemptionSettings');
      case AlarmHealthFix.fullScreenIntent:
        return _invoke('openFullScreenIntentSettings');
      case AlarmHealthFix.oemAutostart:
        return _invoke('openOemAutostartSettings');
      case AlarmHealthFix.appDetails:
        return _invoke('openAppDetailsSettings');
    }
  }

  Future<bool> _invoke(String method) async {
    try {
      final ok = await _channel.invokeMethod<bool>(method);
      return ok ?? false;
    } on PlatformException {
      return openAppSettings();
    } on MissingPluginException {
      return openAppSettings();
    }
  }
}

final alarmHealthServiceProvider = Provider<AlarmHealthService>((ref) {
  return AlarmHealthService();
});
