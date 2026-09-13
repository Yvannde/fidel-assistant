import 'dart:convert';

/// Dose planifiée individuelle (ligne medoc) — regroupée en [DoseSlot] pour
/// la planification locale.
class ScheduledDose {
  const ScheduledDose({
    required this.priseId,
    required this.medicamentNom,
    required this.dosage,
    required this.heurePrevue,
    this.traitementId,
    this.maladieNom,
  });

  final String priseId;
  final String medicamentNom;
  final String dosage;
  final DateTime heurePrevue;
  final String? traitementId;
  final String? maladieNom;

  Map<String, dynamic> toJson() => {
        'priseId': priseId,
        'medicamentNom': medicamentNom,
        'dosage': dosage,
        'heurePrevue': heurePrevue.toUtc().toIso8601String(),
        if (traitementId != null) 'traitementId': traitementId,
        if (maladieNom != null) 'maladieNom': maladieNom,
      };

  factory ScheduledDose.fromJson(Map<String, dynamic> json) {
    return ScheduledDose(
      priseId: '${json['priseId'] ?? ''}',
      medicamentNom: '${json['medicamentNom'] ?? ''}',
      dosage: '${json['dosage'] ?? ''}',
      heurePrevue: DateTime.parse('${json['heurePrevue']}').toLocal(),
      traitementId: json['traitementId']?.toString(),
      maladieNom: json['maladieNom']?.toString(),
    );
  }

  /// Encode une liste pour le cache boot / cold start.
  static String encodeList(List<ScheduledDose> doses) =>
      jsonEncode(doses.map((d) => d.toJson()).toList());

  /// Décode le cache ; ignore les entrées invalides.
  static List<ScheduledDose> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <ScheduledDose>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          final dose = ScheduledDose.fromJson(
            Map<String, dynamic>.from(item),
          );
          if (dose.priseId.isEmpty) continue;
          out.add(dose);
        } catch (_) {}
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// Signature stable pour une dose seule (tests / fingerprints legacy).
  static String signature({
    required ScheduledDose dose,
    required int preavisMinutes,
    required bool discreet,
    required String audioKey,
  }) {
    final ms = dose.heurePrevue.toUtc().millisecondsSinceEpoch;
    return '$ms|${dose.traitementId ?? ''}|${dose.maladieNom ?? ''}|'
        '${dose.medicamentNom}|${dose.dosage}|$preavisMinutes|'
        '${discreet ? 1 : 0}|$audioKey';
  }

  /// Fingerprint global d’un ensemble de signatures (ordre indépendant).
  static String globalFingerprint(Map<String, String> idToSignature) {
    final keys = idToSignature.keys.toList()..sort();
    final buf = StringBuffer();
    for (final k in keys) {
      buf.write(k);
      buf.write('=');
      buf.write(idToSignature[k]);
      buf.write(';');
    }
    return buf.toString();
  }

  /// `true` si [alarmId] est en cours de sonnerie et ne doit pas être stoppé
  /// par un sync / reschedule.
  static bool shouldProtectRingingAlarm({
    required int alarmId,
    required Set<int> ringingIds,
  }) =>
      ringingIds.contains(alarmId);
}
