/// Les six types acceptés par `constante_service.VALID_TYPES`.
/// Ne rien ajouter ici sans l’ajouter d’abord côté backend.
enum ConstanteType {
  poids('poids', 'kg', ['kg']),
  tension('tension', 'mmHg', ['mmHg']),
  glycemie('glycemie', 'g/L', ['g/L', 'mg/dL']),
  temperature('temperature', '°C', ['°C']),
  sommeil('sommeil', 'h', ['h']),
  humeur('humeur', '/5', ['/5']);

  const ConstanteType(this.code, this.defaultUnit, this.units);

  final String code;
  final String defaultUnit;
  final List<String> units;

  /// La tension est stockée en deux composantes et rendue « 120/80 ».
  bool get isPaired => this == ConstanteType.tension;

  /// Nombre de décimales affichées — la glycémie et la température en méritent une.
  int get decimals => switch (this) {
        ConstanteType.poids => 1,
        ConstanteType.glycemie => 2,
        ConstanteType.temperature => 1,
        ConstanteType.sommeil => 1,
        ConstanteType.humeur => 0,
        ConstanteType.tension => 0,
      };

  static ConstanteType? fromCode(String code) {
    for (final t in ConstanteType.values) {
      if (t.code == code) return t;
    }
    return null;
  }
}

class Constante {
  const Constante({
    required this.id,
    required this.type,
    required this.unite,
    required this.mesureAt,
    required this.systolique,
    this.diastolique,
  });

  final String id;
  final ConstanteType type;
  final String unite;
  final DateTime mesureAt;

  /// Valeur unique, ou systolique pour la tension.
  final double systolique;

  /// Diastolique — seulement pour la tension.
  final double? diastolique;

  /// `valeur` arrive en nombre, sauf pour la tension : chaîne « 120/80 ».
  static Constante? tryParse(Map<String, dynamic> json) {
    final type = ConstanteType.fromCode(json['type']?.toString() ?? '');
    if (type == null) return null;

    final raw = json['valeur'];
    double? first;
    double? second;

    if (type.isPaired) {
      if (raw is Map) {
        first = _toDouble(raw['systolique']);
        second = _toDouble(raw['diastolique']);
      } else {
        final parts = raw?.toString().split('/') ?? const [];
        if (parts.length == 2) {
          first = _toDouble(parts[0]);
          second = _toDouble(parts[1]);
        }
      }
    } else {
      first = raw is Map ? _toDouble(raw['v']) : _toDouble(raw);
    }

    if (first == null) return null;

    return Constante(
      id: json['id'].toString(),
      type: type,
      unite: json['unite'] as String? ?? type.defaultUnit,
      mesureAt: DateTime.tryParse(json['mesure_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      systolique: first,
      diastolique: second,
    );
  }

  static double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim().replaceAll(',', '.'));
    return null;
  }
}

/// Retour de `POST /patients/me/constantes` — le message pédagogique vient
/// du backend, on ne le réécrit pas côté app.
class ConstanteCreated {
  const ConstanteCreated({required this.tendance, required this.message});

  final String tendance;
  final String message;

  factory ConstanteCreated.fromJson(Map<String, dynamic> json) {
    return ConstanteCreated(
      tendance: json['tendance'] as String? ?? 'stable',
      message: json['message'] as String? ?? '',
    );
  }
}

/// Une série prête à tracer, du plus ancien au plus récent.
class ConstanteSeries {
  const ConstanteSeries({required this.type, required this.points});

  final ConstanteType type;
  final List<Constante> points;

  Constante get latest => points.last;

  Constante? get previous =>
      points.length >= 2 ? points[points.length - 2] : null;

  /// Écart brut avec la mesure précédente. Aucune interprétation : le backend
  /// est seul juge de la tendance (`amelioration` / `degradation`).
  double? get delta {
    final prev = previous;
    if (prev == null) return null;
    return latest.systolique - prev.systolique;
  }

  /// Regroupe une liste plate par type, ne garde que les types renseignés,
  /// et trie du type le plus récemment mesuré au plus ancien.
  static List<ConstanteSeries> group(List<Constante> all) {
    final byType = <ConstanteType, List<Constante>>{};
    for (final c in all) {
      byType.putIfAbsent(c.type, () => []).add(c);
    }

    final series = <ConstanteSeries>[];
    for (final entry in byType.entries) {
      final points = [...entry.value]
        ..sort((a, b) => a.mesureAt.compareTo(b.mesureAt));
      series.add(ConstanteSeries(type: entry.key, points: points));
    }

    series.sort(
      (a, b) => b.latest.mesureAt.compareTo(a.latest.mesureAt),
    );
    return series;
  }
}
