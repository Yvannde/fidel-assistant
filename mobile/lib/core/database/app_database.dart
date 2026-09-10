import 'dart:convert';

import 'package:drift/drift.dart';

import '../../features/home/domain/dashboard_models.dart';
import '../../services/sync_outbox.dart';
import 'connection.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    PriseSnapshots,
    TraitementMirrors,
    SyncOutboxEntries,
    DashboardSnapshots,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openAppConnection());

  /// DB mémoire pour tests.
  AppDatabase.memory() : super(openMemoryConnection());

  @override
  int get schemaVersion => 1;

  // --- Prises ---

  Future<List<PriseDuJour>> listPrisesForDate(String dateKey) async {
    final rows = await (select(priseSnapshots)
          ..where((t) => t.dateKey.equals(dateKey))
          ..orderBy([(t) => OrderingTerm.asc(t.heurePrevue)]))
        .get();
    return rows.map(_priseFromRow).toList();
  }

  Future<PriseSnapshot?> getPrise(String id) {
    return (select(priseSnapshots)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> upsertPrises(List<PriseDuJour> prises) async {
    if (prises.isEmpty) return;
    await batch((b) {
      for (final p in prises) {
        final dateKey =
            '${p.heurePrevue.toLocal().year.toString().padLeft(4, '0')}-'
            '${p.heurePrevue.toLocal().month.toString().padLeft(2, '0')}-'
            '${p.heurePrevue.toLocal().day.toString().padLeft(2, '0')}';
        b.insert(
          priseSnapshots,
          PriseSnapshotsCompanion.insert(
            id: p.id,
            dateKey: dateKey,
            heurePrevue: p.heurePrevue.toUtc(),
            statut: p.statut,
            medicamentNom: Value(p.medicamentNom),
            dosage: Value(p.dosage),
            updatedAt: Value(DateTime.now().toUtc()),
            payloadJson: Value(
              jsonEncode({
                'id': p.id,
                'medicament_nom': p.medicamentNom,
                'dosage': p.dosage,
                'heure_prevue': p.heurePrevue.toUtc().toIso8601String(),
                'statut': p.statut,
              }),
            ),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> updatePriseLocal({
    required String id,
    String? statut,
    DateTime? heurePrevue,
  }) async {
    final existing = await getPrise(id);
    if (existing == null) {
      if (statut == null && heurePrevue == null) return;
      final when = (heurePrevue ?? DateTime.now()).toUtc();
      final dateKey =
          '${when.toLocal().year.toString().padLeft(4, '0')}-'
          '${when.toLocal().month.toString().padLeft(2, '0')}-'
          '${when.toLocal().day.toString().padLeft(2, '0')}';
      await into(priseSnapshots).insert(
        PriseSnapshotsCompanion.insert(
          id: id,
          dateKey: dateKey,
          heurePrevue: when,
          statut: statut ?? 'en_attente',
          updatedAt: Value(DateTime.now().toUtc()),
        ),
        mode: InsertMode.insertOrReplace,
      );
      return;
    }
    await (update(priseSnapshots)..where((t) => t.id.equals(id))).write(
      PriseSnapshotsCompanion(
        statut: statut != null ? Value(statut) : const Value.absent(),
        heurePrevue:
            heurePrevue != null ? Value(heurePrevue.toUtc()) : const Value.absent(),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  PriseDuJour _priseFromRow(PriseSnapshot row) {
    if (row.payloadJson != null && row.payloadJson!.isNotEmpty) {
      try {
        return PriseDuJour.fromJson(
          jsonDecode(row.payloadJson!) as Map<String, dynamic>,
        );
      } catch (_) {}
    }
    return PriseDuJour(
      id: row.id,
      medicamentNom: row.medicamentNom,
      dosage: row.dosage,
      heurePrevue: row.heurePrevue.toLocal(),
      statut: row.statut,
    );
  }

  // --- Dashboard meta ---

  Future<void> upsertDashboard(PatientDashboard dashboard) async {
    await upsertPrises(dashboard.prisesAujourdhui);
    await into(dashboardSnapshots).insert(
      DashboardSnapshotsCompanion.insert(
        id: const Value(1),
        prochaineAction: dashboard.prochaineAction,
        medicamentsConfigures: dashboard.medicamentsConfigures,
        notificationsAccordees: dashboard.notificationsAccordees,
        traitementsJson: jsonEncode(
          dashboard.traitements
              .map(
                (t) => {
                  'id': t.id,
                  'maladie_code': t.maladieCode,
                  'maladie_nom': t.maladieNom,
                  'phase': t.phase,
                  'medicaments_configures': t.medicamentsConfigures,
                  if (t.dateDebut != null)
                    'date_debut': t.dateDebut!.toIso8601String(),
                  if (t.jourTraitement != null)
                    'jour_traitement': t.jourTraitement,
                },
              )
              .toList(),
        ),
        updatedAt: DateTime.now().toUtc(),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<PatientDashboard?> readDashboardMeta() async {
    final meta = await (select(dashboardSnapshots)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (meta == null) return null;
    final today = DateTime.now();
    final dateKey =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    final prises = await listPrisesForDate(dateKey);
    List<DashboardTraitement> traitements = const [];
    try {
      final decoded = jsonDecode(meta.traitementsJson);
      if (decoded is List) {
        traitements = decoded
            .whereType<Map>()
            .map(
              (e) => DashboardTraitement.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      }
    } catch (_) {}
    return PatientDashboard(
      prochaineAction: meta.prochaineAction,
      medicamentsConfigures: meta.medicamentsConfigures,
      notificationsAccordees: meta.notificationsAccordees,
      traitements: traitements,
      prisesAujourdhui: prises,
    );
  }

  // --- Traitements mirror ---

  Future<void> upsertTraitements(List<TraitementDetail> details) async {
    await batch((b) {
      for (final t in details) {
        b.insert(
          traitementMirrors,
          TraitementMirrorsCompanion.insert(
            id: t.id,
            payloadJson: jsonEncode({
              'id': t.id,
              if (t.dateDebut != null)
                'date_debut': t.dateDebut!.toIso8601String(),
              if (t.dateFinPrevue != null)
                'date_fin_prevue': t.dateFinPrevue!.toIso8601String(),
              if (t.jourTraitement != null) 'jour_traitement': t.jourTraitement,
            }),
            updatedAt: DateTime.now().toUtc(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<Map<String, TraitementDetail>> readTraitementDetails() async {
    final rows = await select(traitementMirrors).get();
    final out = <String, TraitementDetail>{};
    for (final row in rows) {
      try {
        final m = jsonDecode(row.payloadJson) as Map<String, dynamic>;
        out[row.id] = TraitementDetail.fromJson(m);
      } catch (_) {}
    }
    return out;
  }

  // --- Outbox ---

  Future<int> _nextOutboxSortIndex() async {
    final maxExpr = syncOutboxEntries.sortIndex.max();
    final query = selectOnly(syncOutboxEntries)..addColumns([maxExpr]);
    final row = await query.getSingle();
    final current = row.read(maxExpr);
    return (current ?? -1) + 1;
  }

  Future<SyncOutboxEntry> insertOutboxEntry(SyncOutboxEntry entry) async {
    final sort = await _nextOutboxSortIndex();
    await into(syncOutboxEntries).insert(
      SyncOutboxEntriesCompanion.insert(
        mutationId: entry.mutationId,
        entity: entry.entity,
        entityId: entry.entityId,
        op: entry.op,
        payloadJson: jsonEncode(entry.payload),
        clientTs: entry.clientTs.toUtc(),
        attempts: Value(entry.attempts),
        nextAttemptAt: entry.nextAttemptAt.toUtc(),
        state: entry.state.wireName,
        sortIndex: sort,
      ),
      mode: InsertMode.insertOrReplace,
    );
    return entry;
  }

  Future<List<SyncOutboxEntry>> listAllOutbox() async {
    final rows = await (select(syncOutboxEntries)
          ..orderBy([(t) => OrderingTerm.asc(t.sortIndex)]))
        .get();
    return rows.map(_outboxFromRow).toList();
  }

  Future<List<SyncOutboxEntry>> listActiveOutbox() async {
    final rows = await (select(syncOutboxEntries)
          ..where(
            (t) => t.state.isNotValue(SyncOutboxState.failedPermanent.wireName),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.sortIndex)]))
        .get();
    return rows.map(_outboxFromRow).toList();
  }

  Future<void> updateOutboxEntry(SyncOutboxEntry entry) async {
    await (update(syncOutboxEntries)
          ..where((t) => t.mutationId.equals(entry.mutationId)))
        .write(
      SyncOutboxEntriesCompanion(
        attempts: Value(entry.attempts),
        nextAttemptAt: Value(entry.nextAttemptAt.toUtc()),
        state: Value(entry.state.wireName),
        payloadJson: Value(jsonEncode(entry.payload)),
      ),
    );
  }

  Future<void> deleteOutboxEntry(String mutationId) async {
    await (delete(syncOutboxEntries)
          ..where((t) => t.mutationId.equals(mutationId)))
        .go();
  }

  SyncOutboxEntry _outboxFromRow(OutboxRow row) {
    Map<String, dynamic> payload = {};
    try {
      final decoded = jsonDecode(row.payloadJson);
      if (decoded is Map) {
        payload = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return SyncOutboxEntry(
      mutationId: row.mutationId,
      entity: row.entity,
      entityId: row.entityId,
      op: row.op,
      payload: payload,
      clientTs: row.clientTs.toUtc(),
      attempts: row.attempts,
      nextAttemptAt: row.nextAttemptAt.toUtc(),
      state: SyncOutboxState.fromWire(row.state),
    );
  }
}
