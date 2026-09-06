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

class InfosDraft {
  const InfosDraft({
    this.nomComplet = '',
    this.dateNaissance,
    this.sexe = 'F',
    this.localisation = '',
    this.phone = '',
  });

  final String nomComplet;
  final DateTime? dateNaissance;
  final String sexe;
  final String localisation;
  final String phone;

  InfosDraft copyWith({
    String? nomComplet,
    DateTime? dateNaissance,
    String? sexe,
    String? localisation,
    String? phone,
    bool clearBirth = false,
  }) {
    return InfosDraft(
      nomComplet: nomComplet ?? this.nomComplet,
      dateNaissance: clearBirth ? null : (dateNaissance ?? this.dateNaissance),
      sexe: sexe ?? this.sexe,
      localisation: localisation ?? this.localisation,
      phone: phone ?? this.phone,
    );
  }

  factory InfosDraft.fromMeJson(Map<String, dynamic> json) {
    DateTime? birth;
    final raw = json['date_naissance']?.toString();
    if (raw != null && raw.length >= 10) {
      birth = DateTime.tryParse(raw.substring(0, 10));
    }
    return InfosDraft(
      nomComplet: json['nom_complet'] as String? ?? '',
      dateNaissance: birth,
      sexe: json['sexe'] as String? ?? 'F',
      localisation: json['localisation'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }
}

class TraitementDraft {
  const TraitementDraft({
    this.enTraitement,
    this.maladieIds = const {},
    this.phase = 'en_cours',
  });

  final bool? enTraitement;
  final Set<String> maladieIds;
  final String phase;

  TraitementDraft copyWith({
    bool? enTraitement,
    Set<String>? maladieIds,
    String? phase,
    bool clearEnTraitement = false,
  }) {
    return TraitementDraft(
      enTraitement: clearEnTraitement ? null : (enTraitement ?? this.enTraitement),
      maladieIds: maladieIds ?? this.maladieIds,
      phase: phase ?? this.phase,
    );
  }
}
