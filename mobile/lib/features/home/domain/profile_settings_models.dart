/// Modèles réglages Profil — contrats api-contract / data-model.
class PatientSettings {
  const PatientSettings({
    required this.notificationsAccordees,
    required this.batterieExemptee,
    required this.notificationsDiscretes,
    this.localisation,
    this.nomComplet,
  });

  final bool notificationsAccordees;
  final bool batterieExemptee;
  final bool notificationsDiscretes;
  final String? localisation;
  final String? nomComplet;

  factory PatientSettings.fromJson(Map<String, dynamic> json) {
    return PatientSettings(
      notificationsAccordees: json['notifications_accordees'] as bool? ?? false,
      batterieExemptee: json['batterie_exemptee'] as bool? ?? false,
      notificationsDiscretes: json['notifications_discretes'] as bool? ?? false,
      localisation: json['localisation'] as String?,
      nomComplet: json['nom_complet'] as String?,
    );
  }
}

class ContactUrgence {
  const ContactUrgence({
    required this.id,
    required this.nom,
    required this.telephone,
    required this.relation,
  });

  final String id;
  final String nom;
  final String telephone;
  final String relation;

  factory ContactUrgence.fromJson(Map<String, dynamic> json) {
    return ContactUrgence(
      id: json['id'] as String,
      nom: json['nom'] as String? ?? '',
      telephone: json['telephone'] as String? ?? '',
      relation: json['relation'] as String? ?? '',
    );
  }
}

class PreferenceConsentement {
  const PreferenceConsentement({
    required this.typeAlerte,
    required this.toujoursDemander,
    this.id,
    this.regleAuto,
  });

  final String? id;
  final String typeAlerte;
  final bool toujoursDemander;
  final Map<String, dynamic>? regleAuto;

  factory PreferenceConsentement.fromJson(Map<String, dynamic> json) {
    final raw = json['regle_auto'];
    return PreferenceConsentement(
      id: json['id'] as String?,
      typeAlerte: json['type_alerte'] as String? ?? '',
      toujoursDemander: json['toujours_demander'] as bool? ?? true,
      regleAuto: raw is Map
          ? Map<String, dynamic>.from(raw)
          : null,
    );
  }

  /// Types où une règle auto opt-in a du sens produit (tiers).
  static const configurableAutoTypes = {
    'checkin_absence',
    'constante_degradation',
    'rappel_medicament',
  };
}

class VoixRappel {
  const VoixRappel({
    required this.patientId,
    required this.type,
    this.id,
    this.fichierAudioUrl,
  });

  final String? id;
  final String patientId;
  final String type; // systeme | personnalisee
  final String? fichierAudioUrl;

  bool get isPersonnalisee => type == 'personnalisee';

  factory VoixRappel.fromJson(Map<String, dynamic> json) {
    return VoixRappel(
      id: json['id'] as String?,
      patientId: json['patient_id'] as String? ?? '',
      type: json['type'] as String? ?? 'systeme',
      fichierAudioUrl: json['fichier_audio_url'] as String?,
    );
  }
}
