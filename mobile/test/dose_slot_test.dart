import 'package:flutter_test/flutter_test.dart';

import 'package:fidel_assistant/features/home/domain/dashboard_models.dart';
import 'package:fidel_assistant/services/dose_slot.dart';
import 'package:fidel_assistant/services/reminder_alarm_service.dart';
import 'package:fidel_assistant/services/scheduled_dose.dart';

void main() {
  final h0800 = DateTime(2026, 9, 12, 8, 0);
  final h0815 = DateTime(2026, 9, 12, 8, 15);

  ScheduledDose dose({
    required String id,
    required String nom,
    String? traitementId,
    String? maladieNom,
    DateTime? heure,
    String dosage = '1 cp',
  }) {
    return ScheduledDose(
      priseId: id,
      medicamentNom: nom,
      dosage: dosage,
      heurePrevue: heure ?? h0800,
      traitementId: traitementId,
      maladieNom: maladieNom,
    );
  }

  group('DoseSlot.groupScheduled', () {
    test('5 medocs same maladie × heure → 1 slot', () {
      final doses = [
        for (var i = 1; i <= 5; i++)
          dose(
            id: 'p$i',
            nom: 'Med$i',
            traitementId: 'tb-1',
            maladieNom: 'Tuberculose',
          ),
      ];
      final slots = DoseSlot.groupScheduled(doses);
      expect(slots, hasLength(1));
      expect(slots.first.priseIds, hasLength(5));
      expect(slots.first.maladieNom, 'Tuberculose');
      expect(slots.first.slotId, contains('tb-1'));
    });

    test('2 maladies same heure → 2 slots', () {
      final doses = [
        dose(
          id: 'a1',
          nom: 'Rifampicine',
          traitementId: 'tb',
          maladieNom: 'Tuberculose',
        ),
        dose(
          id: 'b1',
          nom: 'Metformine',
          traitementId: 'db',
          maladieNom: 'Diabète',
        ),
      ];
      final slots = DoseSlot.groupScheduled(doses);
      expect(slots, hasLength(2));
      expect(
        slots.map((s) => s.maladieNom).toSet(),
        {'Tuberculose', 'Diabète'},
      );
    });

    test('same maladie different minutes → 2 slots', () {
      final doses = [
        dose(
          id: 'a',
          nom: 'A',
          traitementId: 'tb',
          maladieNom: 'TB',
          heure: h0800,
        ),
        dose(
          id: 'b',
          nom: 'B',
          traitementId: 'tb',
          maladieNom: 'TB',
          heure: h0815,
        ),
      ];
      expect(DoseSlot.groupScheduled(doses), hasLength(2));
    });
  });

  group('DoseSlot.groupPrises', () {
    test('groups UI prises by traitement × minute', () {
      final prises = [
        PriseDuJour(
          id: '1',
          medicamentNom: 'A',
          dosage: '1',
          heurePrevue: h0800,
          statut: 'en_attente',
          traitementId: 't1',
          maladieNom: 'TB',
        ),
        PriseDuJour(
          id: '2',
          medicamentNom: 'B',
          dosage: '1',
          heurePrevue: h0800,
          statut: 'confirmee',
          traitementId: 't1',
          maladieNom: 'TB',
        ),
      ];
      final slots = DoseSlot.groupPrises(prises);
      expect(slots, hasLength(1));
      expect(slots.first.items, hasLength(2));
    });
  });

  group('DoseSlot.medsBody', () {
    test('lists meds under 6, else count', () {
      final small = DoseSlot(
        slotId: 's',
        maladieNom: 'TB',
        heurePrevue: h0800,
        items: const [
          DoseSlotItem(priseId: '1', medicamentNom: 'A', dosage: '1'),
          DoseSlotItem(priseId: '2', medicamentNom: 'B', dosage: '2'),
        ],
      );
      expect(small.medsBody(), contains('A · 1'));
      expect(small.medsBody(), contains('B · 2'));

      final big = DoseSlot(
        slotId: 's2',
        maladieNom: 'TB',
        heurePrevue: h0800,
        items: [
          for (var i = 0; i < 7; i++)
            DoseSlotItem(priseId: '$i', medicamentNom: 'M$i', dosage: '1'),
        ],
      );
      expect(big.medsBody(en: false), '7 médicaments');
      expect(big.medsBody(en: true), '7 medications');
    });
  });

  group('preavis cancel id', () {
    test('preavisNotificationId derived from slotId is stable', () {
      final slotId = DoseSlot.buildSlotId(
        traitementId: 'tb-1',
        heurePrevue: h0800,
      );
      final a = ReminderAlarmService.preavisNotificationId(slotId);
      final b = ReminderAlarmService.preavisNotificationId(slotId);
      expect(a, b);
      expect(a, isNot(ReminderAlarmService.alarmNotificationId(slotId)));
      expect(a, isNot(ReminderAlarmService.markNotificationId(slotId)));
    });

    test('cancelPreavisStatic is callable (no throw on empty)', () async {
      await ReminderAlarmService.cancelPreavisStatic('');
    });
  });

  group('DoseSlot.findNextUntaken', () {
    final h2000 = DateTime(2026, 9, 12, 20, 0);
    final h2100 = DateTime(2026, 9, 12, 21, 0);
    final now = DateTime(2026, 9, 12, 21, 18);

    PriseDuJour prise({
      required String id,
      required String nom,
      String statut = 'en_attente',
      DateTime? heure,
      String? traitementId,
      String? maladieNom,
    }) {
      return PriseDuJour(
        id: id,
        medicamentNom: nom,
        dosage: '500 mg',
        heurePrevue: heure ?? h2000,
        statut: statut,
        traitementId: traitementId,
        maladieNom: maladieNom,
      );
    }

    test('returns overdue slot before upcoming', () {
      final prises = [
        prise(id: 'late', nom: 'Metformine', heure: h2000, maladieNom: 'Diabète'),
        prise(id: 'next', nom: 'Aspirine', heure: h2100, maladieNom: 'HTA'),
      ];
      final slot = DoseSlot.findNextUntaken(prises, now);
      expect(slot?.maladieNom, 'Diabète');
      expect(slot?.priseIds, ['late']);
    });

    test('groups multi-medocs into one next slot', () {
      final prises = [
        for (var i = 1; i <= 3; i++)
          prise(
            id: 'p$i',
            nom: 'Med$i',
            traitementId: 'tb',
            maladieNom: 'Tuberculose',
          ),
      ];
      final slot = DoseSlot.findNextUntaken(prises, now);
      expect(slot?.priseIds, hasLength(3));
      expect(slot?.maladieNom, 'Tuberculose');
    });

    test('returns null when all confirmed', () {
      final prises = [
        prise(id: '1', nom: 'A', statut: 'confirmee'),
        prise(id: '2', nom: 'B', statut: 'confirmee'),
      ];
      expect(DoseSlot.findNextUntaken(prises, now), isNull);
    });

    test('two diseases same hour → overdue first in sort order', () {
      final prises = [
        prise(
          id: 'tb',
          nom: 'Rifa',
          heure: h2000,
          traitementId: 'tb',
          maladieNom: 'Tuberculose',
        ),
        prise(
          id: 'db',
          nom: 'Metformine',
          heure: h2000,
          traitementId: 'db',
          maladieNom: 'Diabète',
        ),
      ];
      final slot = DoseSlot.findNextUntaken(prises, now);
      expect(slot, isNotNull);
      expect(DoseSlot.pendingPriseIds(slot!, prises), hasLength(1));
    });
  });

  group('DoseSlot.fromPayload compat', () {
    test('legacy single priseId builds 1-item slot', () {
      final slot = DoseSlot.fromPayload({
        'priseId': 'p1',
        'medicamentNom': 'Rifa',
        'dosage': '150',
        'heurePrevue': h0800.toUtc().toIso8601String(),
        'maladieNom': 'TB',
        'traitementId': 't1',
      });
      expect(slot.priseIds, ['p1']);
      expect(slot.maladieNom, 'TB');
      expect(slot.items.first.medicamentNom, 'Rifa');
    });
  });
}
