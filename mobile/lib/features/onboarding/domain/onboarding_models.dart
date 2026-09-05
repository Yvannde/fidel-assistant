class MaladieCatalogItem {
  const MaladieCatalogItem({
    required this.id,
    required this.code,
    required this.nom,
    this.description,
  });

  final String id;
  final String code;
  final String nom;
  final String? description;

  factory MaladieCatalogItem.fromJson(Map<String, dynamic> json) {
    return MaladieCatalogItem(
      id: json['id'].toString(),
      code: json['code'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      description: json['description'] as String?,
    );
  }
}

class TraitementSelection {
  const TraitementSelection({
    required this.maladieId,
    required this.phase,
  });

  final String maladieId;
  final String phase;

  Map<String, dynamic> toJson() => {
        'maladie_id': maladieId,
        'phase': phase,
      };
}

class OnboardingStatus {
  const OnboardingStatus({
    required this.onboardingStep,
    required this.hasPatientProfile,
    required this.isAidant,
  });

  final String onboardingStep;
  final bool hasPatientProfile;
  final bool isAidant;

  factory OnboardingStatus.fromJson(Map<String, dynamic> json) {
    return OnboardingStatus(
      onboardingStep: json['onboarding_step'] as String? ?? 'infos',
      hasPatientProfile: json['has_patient_profile'] as bool? ?? false,
      isAidant: json['is_aidant'] as bool? ?? false,
    );
  }
}
