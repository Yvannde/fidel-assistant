class AidantPermissions {
  const AidantPermissions({
    required this.observance,
    required this.constantes,
  });

  final bool observance;
  final bool constantes;

  factory AidantPermissions.fromJson(Map<String, dynamic>? json) {
    return AidantPermissions(
      observance: json?['observance'] as bool? ?? true,
      constantes: json?['constantes'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'observance': observance,
        'constantes': constantes,
      };

  AidantPermissions copyWith({bool? observance, bool? constantes}) {
    return AidantPermissions(
      observance: observance ?? this.observance,
      constantes: constantes ?? this.constantes,
    );
  }
}

class AidantRelation {
  const AidantRelation({
    required this.id,
    required this.nom,
    required this.statut,
    required this.permissions,
  });

  final String id;
  final String? nom;
  final String statut;
  final AidantPermissions permissions;

  String get displayName {
    final n = nom?.trim();
    if (n == null || n.isEmpty) return '—';
    return n;
  }

  String get initial {
    final n = displayName.trim();
    if (n.isEmpty || n == '—') return '?';
    return n[0].toUpperCase();
  }

  factory AidantRelation.fromJson(Map<String, dynamic> json) {
    return AidantRelation(
      id: json['aidant_id']?.toString() ?? '',
      nom: json['nom'] as String?,
      statut: json['statut'] as String? ?? 'actif',
      permissions: AidantPermissions.fromJson(
        json['niveau_permission'] is Map
            ? Map<String, dynamic>.from(json['niveau_permission'] as Map)
            : null,
      ),
    );
  }
}

class AidantPatient {
  const AidantPatient({
    required this.id,
    required this.prenom,
    required this.permissions,
  });

  final String id;
  final String prenom;
  final AidantPermissions permissions;

  String get displayName {
    final value = prenom.trim();
    return value.isEmpty ? 'Patient' : value;
  }

  String get initial {
    final value = displayName.trim();
    return value.isEmpty ? '?' : value[0].toUpperCase();
  }

  factory AidantPatient.fromJson(Map<String, dynamic> json) {
    return AidantPatient(
      id: json['patient_id']?.toString() ?? '',
      prenom: json['prenom'] as String? ?? '',
      permissions: AidantPermissions.fromJson(
        json['niveau_permission'] is Map
            ? Map<String, dynamic>.from(json['niveau_permission'] as Map)
            : null,
      ),
    );
  }
}

class AidantObservance {
  const AidantObservance({
    required this.patientId,
    required this.patientPrenom,
    required this.depuis,
    required this.jusquA,
    required this.total,
    required this.confirmees,
    required this.manquees,
    required this.enAttente,
    required this.tauxObservance,
  });

  final String patientId;
  final String patientPrenom;
  final DateTime depuis;
  final DateTime jusquA;
  final int total;
  final int confirmees;
  final int manquees;
  final int enAttente;
  final double? tauxObservance;

  int get percent => ((tauxObservance ?? 0) * 100).round().clamp(0, 100);

  factory AidantObservance.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(String key) =>
        DateTime.tryParse(json[key]?.toString() ?? '')?.toLocal() ??
        DateTime.now();
    return AidantObservance(
      patientId: json['patient_id']?.toString() ?? '',
      patientPrenom: json['patient_prenom'] as String? ?? '',
      depuis: parseDate('depuis'),
      jusquA: parseDate('jusqu_a'),
      total: (json['total'] as num?)?.toInt() ?? 0,
      confirmees: (json['confirmees'] as num?)?.toInt() ?? 0,
      manquees: (json['manquees'] as num?)?.toInt() ?? 0,
      enAttente: (json['en_attente'] as num?)?.toInt() ?? 0,
      tauxObservance: (json['taux_observance'] as num?)?.toDouble(),
    );
  }
}

class SosTicket {
  const SosTicket({
    required this.id,
    required this.annulableJusquA,
  });

  final String id;
  final DateTime annulableJusquA;

  factory SosTicket.fromJson(Map<String, dynamic> json) {
    return SosTicket(
      id: json['sos_id']?.toString() ?? '',
      annulableJusquA:
          DateTime.tryParse(json['annulable_jusqu_a']?.toString() ?? '')
              ?.toLocal() ??
          DateTime.now(),
    );
  }
}
