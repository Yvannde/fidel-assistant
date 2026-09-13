import 'constante_models.dart';
import 'dashboard_models.dart';
import 'health_priorities.dart';

/// Projection pure des constantes pour l’onglet Santé.
class HealthViewModel {
  const HealthViewModel({
    required this.constantes,
    required this.traitements,
  });

  final List<Constante> constantes;
  final List<DashboardTraitement> traitements;

  List<ConstanteSeries> get series => ConstanteSeries.group(constantes);

  ConstanteSeries? seriesFor(ConstanteType type) {
    for (final s in series) {
      if (s.type == type) return s;
    }
    return null;
  }

  Constante? get latestOverall {
    if (constantes.isEmpty) return null;
    final sorted = [...constantes]
      ..sort((a, b) => b.mesureAt.compareTo(a.mesureAt));
    return sorted.first;
  }

  List<Constante> get recentConstantes {
    final sorted = [...constantes]
      ..sort((a, b) => b.mesureAt.compareTo(a.mesureAt));
    return sorted.take(15).toList();
  }

  List<ConstanteType> get displayOrder =>
      HealthPriorities.displayOrder(traitements);

  Set<ConstanteType> get recommended =>
      HealthPriorities.recommendedFor(traitements);

  List<ConstanteType> get recommendedOrdered => [
        for (final type in displayOrder)
          if (recommended.contains(type)) type,
      ];
}
