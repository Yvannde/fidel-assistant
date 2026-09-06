class HomeProfile {
  const HomeProfile({
    required this.nomComplet,
    required this.hasPatientProfile,
    required this.isAidant,
  });

  final String nomComplet;
  final bool hasPatientProfile;
  final bool isAidant;

  String get firstName {
    final parts = nomComplet.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '';
    final raw = parts.first;
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }

  factory HomeProfile.fromMeJson(Map<String, dynamic> json) {
    return HomeProfile(
      nomComplet: json['nom_complet'] as String? ?? '',
      hasPatientProfile: json['has_patient_profile'] as bool? ?? false,
      isAidant: json['is_aidant'] as bool? ?? false,
    );
  }
}

class DoseSuggestion {
  const DoseSuggestion({
    required this.nom,
    required this.dosage,
    required this.forme,
    this.horaires = const [],
  });

  final String nom;
  final String dosage;
  final String forme;
  final List<String> horaires;

  factory DoseSuggestion.fromJson(Map<String, dynamic> json) {
    final raw = json['horaires_suggestion'];
    final hours = <String>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map && item['heure'] != null) {
          hours.add(item['heure'].toString());
        } else if (item is String) {
          hours.add(item);
        }
      }
    }
    return DoseSuggestion(
      nom: json['nom'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      forme: json['forme'] as String? ?? 'comprime',
      horaires: hours,
    );
  }
}

class DashboardTraitement {
  const DashboardTraitement({
    required this.id,
    required this.maladieNom,
    required this.phase,
    required this.medicamentsConfigures,
    this.suggestions = const [],
  });

  final String id;
  final String maladieNom;
  final String phase;
  final bool medicamentsConfigures;
  final List<DoseSuggestion> suggestions;

  factory DashboardTraitement.fromJson(Map<String, dynamic> json) {
    final raw = json['suggestions_medicaments'];
    return DashboardTraitement(
      id: json['id'].toString(),
      maladieNom: json['maladie_nom'] as String? ?? '',
      phase: json['phase'] as String? ?? '',
      medicamentsConfigures: json['medicaments_configures'] as bool? ?? false,
      suggestions: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => DoseSuggestion.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

class PriseDuJour {
  const PriseDuJour({
    required this.id,
    required this.medicamentNom,
    required this.dosage,
    required this.heurePrevue,
    required this.statut,
  });

  final String id;
  final String medicamentNom;
  final String dosage;
  final DateTime heurePrevue;
  final String statut;

  bool get isPending => statut == 'en_attente';
  bool get isTaken => statut == 'confirmee';
  bool get isMissed => statut == 'manquee';

  bool isLate(DateTime now) =>
      isMissed || (isPending && heurePrevue.isBefore(now));

  factory PriseDuJour.fromJson(Map<String, dynamic> json) {
    return PriseDuJour(
      id: json['id'].toString(),
      medicamentNom: json['medicament_nom'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      heurePrevue:
          DateTime.tryParse(json['heure_prevue']?.toString() ?? '') ??
              DateTime.now(),
      statut: json['statut'] as String? ?? 'en_attente',
    );
  }
}

class PatientDashboard {
  const PatientDashboard({
    required this.prochaineAction,
    required this.medicamentsConfigures,
    required this.notificationsAccordees,
    required this.traitements,
    required this.prisesAujourdhui,
  });

  final String prochaineAction;
  final bool medicamentsConfigures;
  final bool notificationsAccordees;
  final List<DashboardTraitement> traitements;
  final List<PriseDuJour> prisesAujourdhui;

  int pendingCount(DateTime now) =>
      prisesAujourdhui.where((p) => p.isPending && !p.isLate(now)).length;

  int takenCount() => prisesAujourdhui.where((p) => p.isTaken).length;

  int lateCount(DateTime now) =>
      prisesAujourdhui.where((p) => p.isLate(now)).length;

  PriseDuJour? nextDose(DateTime now) {
    final pending = prisesAujourdhui.where((p) => p.isPending).toList()
      ..sort((a, b) => a.heurePrevue.compareTo(b.heurePrevue));
    for (final p in pending) {
      if (!p.heurePrevue.isBefore(now)) return p;
    }
    return pending.isEmpty ? null : pending.first;
  }

  DashboardTraitement? get firstUnconfigured {
    for (final t in traitements) {
      if (!t.medicamentsConfigures) return t;
    }
    return null;
  }

  factory PatientDashboard.fromJson(Map<String, dynamic> json) {
    final traitements = json['traitements'];
    final prises = json['prises_aujourdhui'];
    return PatientDashboard(
      prochaineAction: json['prochaine_action'] as String? ?? 'aucune',
      medicamentsConfigures: json['medicaments_configures'] as bool? ?? false,
      notificationsAccordees:
          json['notifications_accordees'] as bool? ?? false,
      traitements: traitements is List
          ? traitements
              .whereType<Map>()
              .map(
                (e) => DashboardTraitement.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
          : const [],
      prisesAujourdhui: prises is List
          ? prises
              .whereType<Map>()
              .map((e) => PriseDuJour.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}
