import 'scheduled_dose.dart';
import '../features/home/domain/dashboard_models.dart';

/// Une ligne médicament dans un [DoseSlot].
class DoseSlotItem {
  const DoseSlotItem({
    required this.priseId,
    required this.medicamentNom,
    required this.dosage,
  });

  final String priseId;
  final String medicamentNom;
  final String dosage;

  Map<String, dynamic> toJson() => {
        'priseId': priseId,
        'medicamentNom': medicamentNom,
        'dosage': dosage,
      };

  factory DoseSlotItem.fromJson(Map<String, dynamic> json) {
    return DoseSlotItem(
      priseId: '${json['priseId'] ?? ''}',
      medicamentNom: '${json['medicamentNom'] ?? ''}',
      dosage: '${json['dosage'] ?? ''}',
    );
  }

  String get label {
    final nom = medicamentNom.trim();
    final dose = dosage.trim();
    if (nom.isEmpty) return dose;
    if (dose.isEmpty) return nom;
    return '$nom · $dose';
  }
}

/// Créneau thérapeutique = même maladie/traitement × même minute locale.
///
/// Unité de planification : 1 préavis + 1 alarme H0 + 1 marquage H+5 par slot.
class DoseSlot {
  const DoseSlot({
    required this.slotId,
    required this.heurePrevue,
    required this.items,
    this.traitementId,
    this.maladieNom = '',
  });

  final String slotId;
  final String? traitementId;
  final String maladieNom;
  final DateTime heurePrevue;
  final List<DoseSlotItem> items;

  List<String> get priseIds => [for (final i in items) i.priseId];

  bool get isEmpty => items.isEmpty;

  /// Identifiant stable : `traitementId|yyyy-MM-dd|HH:mm` (fallback `_` si absent).
  static String buildSlotId({
    String? traitementId,
    required DateTime heurePrevue,
  }) {
    final local = heurePrevue.isUtc ? heurePrevue.toLocal() : heurePrevue;
    final day =
        '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
    final hm =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    final t =
        (traitementId != null && traitementId.isNotEmpty) ? traitementId : '_';
    return '$t|$day|$hm';
  }

  /// Groupe des [ScheduledDose] pending en slots maladie × heure.
  static List<DoseSlot> groupScheduled(Iterable<ScheduledDose> doses) {
    final buckets = <String, List<ScheduledDose>>{};
    for (final d in doses) {
      final id = buildSlotId(
        traitementId: d.traitementId,
        heurePrevue: d.heurePrevue,
      );
      buckets.putIfAbsent(id, () => []).add(d);
    }
    return _slotsFromBuckets(buckets);
  }

  /// Groupe des [PriseDuJour] (tous statuts) pour l’UI Accueil.
  static List<DoseSlot> groupPrises(Iterable<PriseDuJour> prises) {
    final buckets = <String, List<PriseDuJour>>{};
    for (final p in prises) {
      final id = buildSlotId(
        traitementId: p.traitementId,
        heurePrevue: p.heurePrevue,
      );
      buckets.putIfAbsent(id, () => []).add(p);
    }
    final slots = <DoseSlot>[];
    for (final entry in buckets.entries) {
      final list = [...entry.value]
        ..sort((a, b) => a.medicamentNom.compareTo(b.medicamentNom));
      final first = list.first;
      slots.add(
        DoseSlot(
          slotId: entry.key,
          traitementId: first.traitementId,
          maladieNom: first.maladieNom ?? '',
          heurePrevue: _minuteFloor(first.heurePrevue),
          items: [
            for (final p in list)
              DoseSlotItem(
                priseId: p.id,
                medicamentNom: p.medicamentNom,
                dosage: p.dosage,
              ),
          ],
        ),
      );
    }
    slots.sort((a, b) => a.heurePrevue.compareTo(b.heurePrevue));
    return slots;
  }

  static List<DoseSlot> _slotsFromBuckets(
    Map<String, List<ScheduledDose>> buckets,
  ) {
    final slots = <DoseSlot>[];
    for (final entry in buckets.entries) {
      final list = [...entry.value]
        ..sort((a, b) => a.medicamentNom.compareTo(b.medicamentNom));
      final first = list.first;
      slots.add(
        DoseSlot(
          slotId: entry.key,
          traitementId: first.traitementId,
          maladieNom: first.maladieNom ?? '',
          heurePrevue: _minuteFloor(first.heurePrevue),
          items: [
            for (final d in list)
              DoseSlotItem(
                priseId: d.priseId,
                medicamentNom: d.medicamentNom,
                dosage: d.dosage,
              ),
          ],
        ),
      );
    }
    slots.sort((a, b) => a.heurePrevue.compareTo(b.heurePrevue));
    return slots;
  }

  static DateTime _minuteFloor(DateTime t) {
    final local = t.isUtc ? t.toLocal() : t;
    return DateTime(local.year, local.month, local.day, local.hour, local.minute);
  }

  /// Corps notif : liste medocs, ou « N médicaments » si > [maxListed].
  String medsBody({int maxListed = 6, bool en = false}) {
    if (items.length > maxListed) {
      return en
          ? '${items.length} medications'
          : '${items.length} médicaments';
    }
    return [
      for (final i in items)
        if (i.label.isNotEmpty) i.label,
    ].join('\n');
  }

  /// Signature stable pour le reschedule différentiel (ordre des medocs indépendant).
  static String signature({
    required DoseSlot slot,
    required int preavisMinutes,
    required bool discreet,
    required String audioKey,
  }) {
    final ms = slot.heurePrevue.toUtc().millisecondsSinceEpoch;
    final ids = [...slot.priseIds]..sort();
    final meds = [
      for (final i in [...slot.items]
        ..sort((a, b) => a.priseId.compareTo(b.priseId)))
        '${i.priseId}:${i.medicamentNom}|${i.dosage}',
    ].join(',');
    return '$ms|${slot.maladieNom}|$meds|${ids.join(',')}|$preavisMinutes|'
        '${discreet ? 1 : 0}|$audioKey';
  }

  Map<String, dynamic> toPayload({required String kind}) => {
        'kind': kind,
        'slotId': slotId,
        'priseIds': priseIds,
        'priseId': items.isNotEmpty ? items.first.priseId : '',
        'traitementId': traitementId,
        'maladieNom': maladieNom,
        'medicamentNom': items.isNotEmpty ? items.first.medicamentNom : '',
        'dosage': items.isNotEmpty ? items.first.dosage : '',
        'heurePrevue': heurePrevue.toUtc().toIso8601String(),
        'items': [for (final i in items) i.toJson()],
      };

  factory DoseSlot.fromPayload(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <DoseSlotItem>[];
    if (rawItems is List) {
      for (final e in rawItems) {
        if (e is Map) {
          items.add(DoseSlotItem.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    if (items.isEmpty) {
      final ids = json['priseIds'];
      if (ids is List && ids.isNotEmpty) {
        for (final id in ids) {
          items.add(
            DoseSlotItem(
              priseId: '$id',
              medicamentNom: '${json['medicamentNom'] ?? ''}',
              dosage: '${json['dosage'] ?? ''}',
            ),
          );
        }
      } else {
        final priseId = '${json['priseId'] ?? ''}';
        if (priseId.isNotEmpty) {
          items.add(
            DoseSlotItem(
              priseId: priseId,
              medicamentNom: '${json['medicamentNom'] ?? ''}',
              dosage: '${json['dosage'] ?? ''}',
            ),
          );
        }
      }
    }

    final heureRaw = json['heurePrevue']?.toString();
    final heure = heureRaw != null && heureRaw.isNotEmpty
        ? (DateTime.tryParse(heureRaw)?.toLocal() ?? DateTime.now())
        : DateTime.now();
    final traitementId = json['traitementId']?.toString();
    final slotId = '${json['slotId'] ?? ''}'.isNotEmpty
        ? '${json['slotId']}'
        : buildSlotId(traitementId: traitementId, heurePrevue: heure);

    return DoseSlot(
      slotId: slotId,
      traitementId: traitementId,
      maladieNom: '${json['maladieNom'] ?? ''}',
      heurePrevue: heure,
      items: items,
    );
  }

  DoseSlot copyWithHeure(DateTime when) {
    return DoseSlot(
      slotId: buildSlotId(traitementId: traitementId, heurePrevue: when),
      traitementId: traitementId,
      maladieNom: maladieNom,
      heurePrevue: _minuteFloor(when),
      items: items,
    );
  }
}
