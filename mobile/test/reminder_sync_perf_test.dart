import 'package:flutter_test/flutter_test.dart';

import 'package:fidel_assistant/features/home/domain/dashboard_models.dart';
import 'package:fidel_assistant/services/reminder_sync_perf.dart';
import 'package:fidel_assistant/services/scheduled_dose.dart';

void main() {
  group('ReminderSyncPerf.extraDaysToFetch', () {
    test('morning needs J+1 and J+2 within 48h', () {
      final now = DateTime(2026, 9, 10, 8, 0);
      expect(ReminderSyncPerf.extraDaysToFetch(now), 2);
    });

    test('late evening still reaches J+2', () {
      final now = DateTime(2026, 9, 10, 22, 0);
      expect(ReminderSyncPerf.extraDaysToFetch(now), 2);
    });

    test('short horizon stays on J0', () {
      final now = DateTime(2026, 9, 10, 8, 0);
      expect(
        ReminderSyncPerf.extraDaysToFetch(
          now,
          horizon: const Duration(hours: 4),
        ),
        0,
      );
    });
  });

  group('ReminderSyncPerf.isWithinHorizon', () {
    final now = DateTime(2026, 9, 10, 12, 0);

    test('includes soon and excludes far future', () {
      expect(
        ReminderSyncPerf.isWithinHorizon(now.add(const Duration(hours: 1)), now),
        isTrue,
      );
      expect(
        ReminderSyncPerf.isWithinHorizon(
          now.add(const Duration(hours: 49)),
          now,
        ),
        isFalse,
      );
    });

    test('excludes doses too far in the past', () {
      expect(
        ReminderSyncPerf.isWithinHorizon(
          now.subtract(const Duration(minutes: 20)),
          now,
        ),
        isFalse,
      );
    });
  });

  group('ReminderSyncPerf fingerprints', () {
    test('dashboard fingerprint ignores taken doses and is order-stable', () {
      final a = ReminderSyncPerf.dashboardPendingFingerprint([
        _prise('p2', DateTime.utc(2026, 9, 10, 18), pending: true),
        _prise('p1', DateTime.utc(2026, 9, 10, 12), pending: true),
        _prise('p3', DateTime.utc(2026, 9, 10, 9), pending: false),
      ]);
      final b = ReminderSyncPerf.dashboardPendingFingerprint([
        _prise('p1', DateTime.utc(2026, 9, 10, 12), pending: true),
        _prise('p2', DateTime.utc(2026, 9, 10, 18), pending: true),
      ]);
      expect(a, b);
    });

    test('syncGateKey changes when preavis changes', () {
      final g1 = ReminderSyncPerf.syncGateKey(
        dashboardFingerprint: 'x',
        preavisMinutes: 5,
        discreet: false,
        useCustomVoice: false,
        customVoiceExt: null,
      );
      final g2 = ReminderSyncPerf.syncGateKey(
        dashboardFingerprint: 'x',
        preavisMinutes: 10,
        discreet: false,
        useCustomVoice: false,
        customVoiceExt: null,
      );
      expect(g1, isNot(equals(g2)));
    });

    test('voixMetaKey distinguishes system vs custom', () {
      expect(
        ReminderSyncPerf.voixMetaKey(
          id: null,
          fichierAudioUrl: null,
          isPersonnalisee: false,
        ),
        'systeme',
      );
      expect(
        ReminderSyncPerf.voixMetaKey(
          id: 'v1',
          fichierAudioUrl: '/a',
          isPersonnalisee: true,
        ),
        'custom|v1|/a',
      );
    });
  });

  group('ReminderSyncPerf.filterHorizon', () {
    test('keeps only in-window doses', () {
      final now = DateTime(2026, 9, 10, 12);
      final kept = ReminderSyncPerf.filterHorizon(
        [
          ScheduledDose(
            priseId: 'soon',
            medicamentNom: 'A',
            dosage: '1',
            heurePrevue: now.add(const Duration(hours: 3)),
          ),
          ScheduledDose(
            priseId: 'far',
            medicamentNom: 'B',
            dosage: '1',
            heurePrevue: now.add(const Duration(hours: 60)),
          ),
        ],
        now,
      );
      expect(kept.map((d) => d.priseId), ['soon']);
    });
  });
}

PriseDuJour _prise(String id, DateTime when, {required bool pending}) {
  return PriseDuJour(
    id: id,
    medicamentNom: 'Med',
    dosage: '1 cp',
    heurePrevue: when,
    statut: pending ? 'en_attente' : 'confirmee',
  );
}
