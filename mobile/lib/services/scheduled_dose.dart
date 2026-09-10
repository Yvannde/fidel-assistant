/// Dose planifiée : alarme H0 + notification de marquage H0+5.
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
