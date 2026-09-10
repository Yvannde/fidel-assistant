import 'package:flutter_test/flutter_test.dart';

import 'package:fidel_assistant/services/reminder_alarm_service.dart';

void main() {
  test('preavis / alarm / mark IDs are distinct per prise', () {
    const ids = [
      'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      '11111111-2222-3333-4444-555555555555',
      'prise-short',
    ];
    for (final priseId in ids) {
      final a = ReminderAlarmService.alarmNotificationId(priseId);
      final m = ReminderAlarmService.markNotificationId(priseId);
      final p = ReminderAlarmService.preavisNotificationId(priseId);
      expect(a, isNot(equals(m)));
      expect(a, isNot(equals(p)));
      expect(m, isNot(equals(p)));
      expect(a, greaterThan(0));
      expect(m, greaterThan(0));
      expect(p, greaterThan(0));
    }
  });
}
