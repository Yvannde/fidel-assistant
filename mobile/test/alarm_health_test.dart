import 'package:fidel_assistant/services/alarm_health.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlarmHealthStatus.oemTipKey', () {
    test('detects Xiaomi family', () {
      expect(AlarmHealthStatus.oemTipKey('Xiaomi', 'Redmi'), 'xiaomi');
      expect(AlarmHealthStatus.oemTipKey('POCO', 'poco'), 'xiaomi');
    });

    test('detects Transsion family', () {
      expect(AlarmHealthStatus.oemTipKey('TECNO', 'TECNO'), 'transsion');
      expect(AlarmHealthStatus.oemTipKey('Infinix', 'Infinix'), 'transsion');
    });

    test('detects Samsung and generic', () {
      expect(AlarmHealthStatus.oemTipKey('samsung', 'samsung'), 'samsung');
      expect(AlarmHealthStatus.oemTipKey('Google', 'google'), 'generic');
    });
  });

  group('AlarmHealthStatus.allCoreOk', () {
    test('true only when every core check passes', () {
      const ok = AlarmHealthStatus(
        notifications: true,
        exactAlarm: true,
        batteryExempt: true,
        fullScreenIntent: true,
        manufacturer: 'x',
        brand: 'x',
        sdkInt: 34,
        oemAutostartLikelyNeeded: false,
      );
      expect(ok.allCoreOk, isTrue);

      const bad = AlarmHealthStatus(
        notifications: true,
        exactAlarm: false,
        batteryExempt: true,
        fullScreenIntent: true,
        manufacturer: 'x',
        brand: 'x',
        sdkInt: 34,
        oemAutostartLikelyNeeded: true,
      );
      expect(bad.allCoreOk, isFalse);
    });
  });

  group('AlarmHealthStatus.fromMap', () {
    test('parses channel payload', () {
      final s = AlarmHealthStatus.fromMap({
        'notifications': true,
        'exactAlarm': false,
        'batteryExempt': true,
        'fullScreenIntent': true,
        'manufacturer': 'Samsung',
        'brand': 'samsung',
        'sdkInt': 33,
        'oemAutostartLikelyNeeded': true,
      });
      expect(s.exactAlarm, isFalse);
      expect(s.tipKey, 'samsung');
      expect(s.oemAutostartLikelyNeeded, isTrue);
    });
  });
}
