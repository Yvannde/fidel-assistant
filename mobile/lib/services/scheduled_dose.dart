import 'dart:convert';

/// Dose planifiée : préavis + alarme H0 + notification de marquage H0+5.
class ScheduledDose {
  const ScheduledDose({
    required this.priseId,
    required this.medicamentNom,
    required this.dosage,
    required this.heurePrevue,
  });

  final String priseId;
  final String medicamentNom;
  final String dosage;
  final DateTime heurePrevue;

  Map<String, dynamic> toJson() => {
        'priseId': priseId,
        'medicamentNom': medicamentNom,
        'dosage': dosage,
        'heurePrevue': heurePrevue.toUtc().toIso8601String(),
      };

  factory ScheduledDose.fromJson(Map<String, dynamic> json) {
    return ScheduledDose(
      priseId: '${json['priseId'] ?? ''}',
      medicamentNom: '${json['medicamentNom'] ?? ''}',
      dosage: '${json['dosage'] ?? ''}',
      heurePrevue: DateTime.parse('${json['heurePrevue']}').toLocal(),
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

  /// Signature stable pour le reschedule différentiel.
  ///
  /// Inclut l’heure, le libellé, le délai de préavis, le mode discret et la
  /// clé audio — tout ce qui impose une replanification locale.
  static String signature({
    required ScheduledDose dose,
    required int preavisMinutes,
    required bool discreet,
    required String audioKey,
  }) {
    final ms = dose.heurePrevue.toUtc().millisecondsSinceEpoch;
    return '$ms|${dose.medicamentNom}|${dose.dosage}|$preavisMinutes|'
        '${discreet ? 1 : 0}|$audioKey';
  }

  /// Fingerprint global d’un ensemble de signatures (ordre indépendant).
  static String globalFingerprint(Map<String, String> priseIdToSignature) {
    final keys = priseIdToSignature.keys.toList()..sort();
    final buf = StringBuffer();
    for (final k in keys) {
      buf.write(k);
      buf.write('=');
      buf.write(priseIdToSignature[k]);
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
