/// Dose planifiée pour une notification locale.
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
}
