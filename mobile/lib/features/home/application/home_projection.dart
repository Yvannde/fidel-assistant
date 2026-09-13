import '../domain/dashboard_models.dart';
import '../../../services/sync_outbox.dart';

/// Projection UI : `snapshot ⊕ outbox` (Phase 3).
class HomeProjection {
  const HomeProjection._();

  /// Applique les mutations outbox FIFO sur une liste de prises snapshot.
  static List<PriseDuJour> applyOutbox({
    required List<PriseDuJour> snapshot,
    required List<SyncOutboxEntry> outbox,
  }) {
    final byId = {for (final p in snapshot) p.id: p};
    final ordered = outbox
        .where(
          (e) =>
              e.entity == 'prise' &&
              e.state != SyncOutboxState.failedPermanent,
        )
        .toList();

    for (final entry in ordered) {
      final current = byId[entry.entityId];
      if (entry.op == 'confirm') {
        if (current == null) {
          byId[entry.entityId] = PriseDuJour(
            id: entry.entityId,
            medicamentNom: '',
            dosage: '',
            heurePrevue: entry.clientTs.toLocal(),
            statut: 'confirmee',
          );
        } else {
          byId[entry.entityId] = current.copyWith(statut: 'confirmee');
        }
      } else if (entry.op == 'report') {
        final raw = entry.payload['nouvelle_heure'] as String?;
        final when = raw != null
            ? (DateTime.tryParse(raw)?.toLocal() ?? current?.heurePrevue)
            : current?.heurePrevue;
        if (when == null) continue;
        if (current == null) {
          byId[entry.entityId] = PriseDuJour(
            id: entry.entityId,
            medicamentNom: '',
            dosage: '',
            heurePrevue: when,
            statut: 'en_attente',
          );
        } else {
          byId[entry.entityId] = current.copyWith(
            heurePrevue: when,
            statut:
                current.statut == 'confirmee' ? 'confirmee' : 'en_attente',
          );
        }
      }
    }

    final list = byId.values.toList()
      ..sort((a, b) => a.heurePrevue.compareTo(b.heurePrevue));
    return list;
  }

  static PatientDashboard projectDashboard({
    required PatientDashboard base,
    required List<SyncOutboxEntry> outbox,
  }) {
    final prises = applyOutbox(
      snapshot: base.prisesAujourdhui,
      outbox: outbox,
    );
    return PatientDashboard(
      prochaineAction: base.prochaineAction,
      medicamentsConfigures: base.medicamentsConfigures,
      notificationsAccordees: base.notificationsAccordees,
      traitements: base.traitements,
      prisesAujourdhui: prises,
    );
  }
}
