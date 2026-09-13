import 'package:flutter_test/flutter_test.dart';

import 'package:fidel_assistant/features/home/domain/constante_models.dart';
import 'package:fidel_assistant/features/home/domain/dashboard_models.dart';
import 'package:fidel_assistant/features/home/domain/health_priorities.dart';

void main() {
  DashboardTraitement traitement(String code) => DashboardTraitement(
        id: code,
        maladieCode: code,
        maladieNom: code,
        phase: 'maintenance',
        medicamentsConfigures: true,
      );

  group('HealthPriorities', () {
    test('TB + diabète → union sans doublon', () {
      final recommended = HealthPriorities.recommendedFor([
        traitement('tuberculose'),
        traitement('diabete'),
      ]);
      expect(recommended, {
        ConstanteType.poids,
        ConstanteType.temperature,
        ConstanteType.glycemie,
      });
    });

    test('displayOrder puts recommended first', () {
      final order = HealthPriorities.displayOrder([traitement('hypertension')]);
      expect(order.first, ConstanteType.tension);
      expect(order, contains(ConstanteType.poids));
      expect(order, hasLength(ConstanteType.values.length));
    });

    test('no traitement → default trio', () {
      final recommended = HealthPriorities.recommendedFor(const []);
      expect(recommended, {
        ConstanteType.poids,
        ConstanteType.tension,
        ConstanteType.glycemie,
      });
    });
  });
}
