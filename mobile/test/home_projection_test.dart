import 'package:flutter_test/flutter_test.dart';

import 'package:fidel_assistant/features/home/application/home_projection.dart';
import 'package:fidel_assistant/features/home/domain/dashboard_models.dart';
import 'package:fidel_assistant/services/sync_outbox.dart';

void main() {
  final base = [
    PriseDuJour(
      id: 'p1',
      medicamentNom: 'Aspi',
      dosage: '100mg',
      heurePrevue: DateTime(2026, 9, 10, 8),
      statut: 'en_attente',
    ),
  ];

  test('confirm projects to confirmee', () {
    final out = HomeProjection.applyOutbox(
      snapshot: base,
      outbox: [
        SyncOutboxEntry(
          mutationId: 'm1',
          entity: 'prise',
          entityId: 'p1',
          op: 'confirm',
          payload: {},
          clientTs: DateTime.utc(2026, 9, 10, 8),
        ),
      ],
    );
    expect(out.single.statut, 'confirmee');
  });

  test('report then confirm FIFO', () {
    final when = DateTime(2026, 9, 10, 10);
    final out = HomeProjection.applyOutbox(
      snapshot: base,
      outbox: [
        SyncOutboxEntry(
          mutationId: 'm1',
          entity: 'prise',
          entityId: 'p1',
          op: 'report',
          payload: {'nouvelle_heure': when.toUtc().toIso8601String()},
          clientTs: DateTime.utc(2026, 9, 10, 8),
        ),
        SyncOutboxEntry(
          mutationId: 'm2',
          entity: 'prise',
          entityId: 'p1',
          op: 'confirm',
          payload: {},
          clientTs: DateTime.utc(2026, 9, 10, 8, 1),
        ),
      ],
    );
    expect(out.single.statut, 'confirmee');
    expect(out.single.heurePrevue, when);
  });

  test('projectDashboard updates prisesAujourdhui', () {
    final dash = PatientDashboard(
      prochaineAction: 'prise',
      medicamentsConfigures: true,
      notificationsAccordees: true,
      traitements: const [],
      prisesAujourdhui: base,
    );
    final projected = HomeProjection.projectDashboard(
      base: dash,
      outbox: [
        SyncOutboxEntry(
          mutationId: 'm1',
          entity: 'prise',
          entityId: 'p1',
          op: 'confirm',
          payload: {},
          clientTs: DateTime.utc(2026, 9, 10),
        ),
      ],
    );
    expect(projected.prisesAujourdhui.single.isTaken, isTrue);
  });
}
