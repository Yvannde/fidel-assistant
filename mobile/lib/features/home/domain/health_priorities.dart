import 'constante_models.dart';
import 'dashboard_models.dart';

/// Priorités de constantes par maladie — aligné sur le seed backend.
abstract final class HealthPriorities {
  static const Map<String, List<ConstanteType>> _byMaladieCode = {
    'tuberculose': [ConstanteType.poids, ConstanteType.temperature],
    'diabete': [ConstanteType.glycemie, ConstanteType.poids],
    'hypertension': [ConstanteType.tension, ConstanteType.poids],
    'vih': [ConstanteType.poids],
    'autre': [ConstanteType.poids, ConstanteType.humeur],
  };

  static const List<ConstanteType> _defaultWhenNoTraitement = [
    ConstanteType.poids,
    ConstanteType.tension,
    ConstanteType.glycemie,
  ];

  /// Types recommandés (union des maladies actives), sans doublon, ordre stable.
  static Set<ConstanteType> recommendedFor(List<DashboardTraitement> traitements) {
    final out = <ConstanteType>{};
    for (final t in traitements) {
      final code = t.maladieCode.trim().toLowerCase();
      final types = _byMaladieCode[code];
      if (types != null) out.addAll(types);
    }
    if (out.isEmpty) return _defaultWhenNoTraitement.toSet();
    return out;
  }

  /// Ordre d’affichage : priorités maladie d’abord, puis les types restants.
  static List<ConstanteType> displayOrder(List<DashboardTraitement> traitements) {
    final ordered = <ConstanteType>[];
    final seen = <ConstanteType>{};

    for (final t in traitements) {
      final types = _byMaladieCode[t.maladieCode.trim().toLowerCase()];
      if (types == null) continue;
      for (final type in types) {
        if (seen.add(type)) ordered.add(type);
      }
    }

    if (ordered.isEmpty) {
      for (final type in _defaultWhenNoTraitement) {
        if (seen.add(type)) ordered.add(type);
      }
    }

    for (final type in ConstanteType.values) {
      if (!seen.contains(type)) ordered.add(type);
    }
    return ordered;
  }
}
