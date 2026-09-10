import 'package:flutter_test/flutter_test.dart';

import 'package:fidel_assistant/services/reminder_alarm_service.dart';
import 'package:fidel_assistant/services/scheduled_dose.dart';

void main() {
  group('ScheduledDose.signature', () {
    final base = ScheduledDose(
      priseId: 'p1',
      medicamentNom: 'Paracetamol',
      dosage: '500 mg',
      heurePrevue: DateTime.utc(2026, 9, 10, 12, 0),
    );

    test('stable for identical inputs', () {
      final a = ScheduledDose.signature(
        dose: base,
        preavisMinutes: 5,
        discreet: false,
        audioKey: 'assets/sounds/x.mp3',
      );
      final b = ScheduledDose.signature(
        dose: base,
        preavisMinutes: 5,
        discreet: false,
        audioKey: 'assets/sounds/x.mp3',
      );
      expect(a, b);
    });

    test('changes when hour changes', () {
      final later = ScheduledDose(
        priseId: base.priseId,
        medicamentNom: base.medicamentNom,
        dosage: base.dosage,
        heurePrevue: base.heurePrevue.add(const Duration(minutes: 15)),
      );
      final a = ScheduledDose.signature(
        dose: base,
        preavisMinutes: 5,
        discreet: false,
        audioKey: 'a',
      );
      final b = ScheduledDose.signature(
        dose: later,
        preavisMinutes: 5,
        discreet: false,
        audioKey: 'a',
      );
      expect(a, isNot(equals(b)));
    });

    test('changes when preavis / discreet / audio change', () {
      final a = ScheduledDose.signature(
        dose: base,
        preavisMinutes: 5,
        discreet: false,
        audioKey: 'a',
      );
      expect(
        ScheduledDose.signature(
          dose: base,
          preavisMinutes: 2,
          discreet: false,
          audioKey: 'a',
        ),
        isNot(equals(a)),
      );
      expect(
        ScheduledDose.signature(
          dose: base,
          preavisMinutes: 5,
          discreet: true,
          audioKey: 'a',
        ),
        isNot(equals(a)),
      );
      expect(
        ScheduledDose.signature(
          dose: base,
          preavisMinutes: 5,
          discreet: false,
          audioKey: 'b',
        ),
        isNot(equals(a)),
      );
    });
  });

  group('ScheduledDose.globalFingerprint', () {
    test('order-independent', () {
      final a = ScheduledDose.globalFingerprint({
        'b': 'sigB',
        'a': 'sigA',
      });
      final b = ScheduledDose.globalFingerprint({
        'a': 'sigA',
        'b': 'sigB',
      });
      expect(a, b);
    });

    test('differs when a signature changes', () {
      final a = ScheduledDose.globalFingerprint({'p1': 'x'});
      final b = ScheduledDose.globalFingerprint({'p1': 'y'});
      expect(a, isNot(equals(b)));
    });
  });

  group('shouldProtectRingingAlarm', () {
    test('protects only ringing ids', () {
      expect(
        ScheduledDose.shouldProtectRingingAlarm(
          alarmId: 42,
          ringingIds: {42, 7},
        ),
        isTrue,
      );
      expect(
        ScheduledDose.shouldProtectRingingAlarm(
          alarmId: 99,
          ringingIds: {42, 7},
        ),
        isFalse,
      );
    });
  });

  group('notification ids', () {
    test('preavis / alarm / mark are distinct', () {
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
      }
    });
  });

  group('ScheduledDose cache encode/decode', () {
    test('round-trips doses', () {
      final when = DateTime.utc(2026, 9, 10, 14, 30);
      final raw = ScheduledDose.encodeList([
        ScheduledDose(
          priseId: 'p1',
          medicamentNom: 'A',
          dosage: '1 cp',
          heurePrevue: when,
        ),
      ]);
      final decoded = ScheduledDose.decodeList(raw);
      expect(decoded, hasLength(1));
      expect(decoded.first.priseId, 'p1');
      expect(decoded.first.medicamentNom, 'A');
      expect(
        decoded.first.heurePrevue.toUtc().millisecondsSinceEpoch,
        when.millisecondsSinceEpoch,
      );
    });

    test('tolerates empty and invalid JSON', () {
      expect(ScheduledDose.decodeList(null), isEmpty);
      expect(ScheduledDose.decodeList(''), isEmpty);
      expect(ScheduledDose.decodeList('not-json'), isEmpty);
      expect(ScheduledDose.decodeList('[]'), isEmpty);
      expect(ScheduledDose.decodeList('[{"priseId":""}]'), isEmpty);
    });
  });
}
