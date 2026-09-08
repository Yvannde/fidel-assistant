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
