import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_assistant/features/home/domain/dashboard_models.dart';
import 'package:fidel_assistant/services/check_in_reminder_service.dart';

void main() {
  group('CheckInEntry levels', () {
    test('four ordered levels', () {
      expect(CheckInEntry.levels, ['tres_mal', 'pas_top', 'ca_va', 'super']);
    });

    test('isPositive for ca_va and super', () {
      final day = DateTime(2026, 9, 13);
      expect(CheckInEntry(date: day, statut: 'ca_va').isPositive, isTrue);
      expect(CheckInEntry(date: day, statut: 'super').isPositive, isTrue);
      expect(CheckInEntry(date: day, statut: 'pas_top').isPositive, isFalse);
      expect(CheckInEntry(date: day, statut: 'tres_mal').isPositive, isFalse);
    });
  });

  group('CheckInReminderService', () {
    test('maps notification actions to statuts', () {
      expect(
        CheckInReminderService.statutFromAction(
          CheckInReminderService.actionTresMal,
        ),
        'tres_mal',
      );
      expect(
        CheckInReminderService.statutFromAction(
          CheckInReminderService.actionPasTop,
        ),
        'pas_top',
      );
      expect(
        CheckInReminderService.statutFromAction(
          CheckInReminderService.actionCaVa,
        ),
        'ca_va',
      );
      expect(
        CheckInReminderService.statutFromAction(
          CheckInReminderService.actionSuper,
        ),
        'super',
      );
      expect(CheckInReminderService.statutFromAction(null), isNull);
      expect(CheckInReminderService.statutFromAction('other'), isNull);
    });

    test('detects check-in payload kind', () {
      expect(
        CheckInReminderService.isCheckInPayload({'kind': 'check_in_daily'}),
        isTrue,
      );
      expect(
        CheckInReminderService.isCheckInPayload({'kind': 'mark'}),
        isFalse,
      );
    });

    test('afternoon hour is 15:00', () {
      expect(CheckInReminderService.hour, 15);
      expect(CheckInReminderService.minute, 0);
    });
  });
}
