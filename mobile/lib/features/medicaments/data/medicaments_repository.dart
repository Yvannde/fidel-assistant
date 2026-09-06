import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import '../../onboarding/domain/onboarding_models.dart';

final medicamentsRepositoryProvider = Provider<MedicamentsRepository>((ref) {
  return MedicamentsRepository(apiClient: ref.watch(apiClientProvider));
});

class MedicamentsRepository {
  MedicamentsRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<MaladieCatalogItem>> listMaladies() async {
    try {
      final res = await _api.get<dynamic>('/onboarding/maladies');
      final data = res.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => MaladieCatalogItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<String> createTraitement({
    required String maladieId,
    required String phase,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/patients/me/traitements',
        data: {
          'maladie_id': maladieId,
          'phase': phase,
        },
      );
      return res.data?['id']?.toString() ?? '';
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> createMedicament({
    required String traitementId,
    required String nom,
    required String dosage,
    String forme = 'comprime',
    required List<String> heures,
  }) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/traitements/$traitementId/medicaments',
        data: {
          'nom': nom.trim(),
          'dosage': dosage.trim(),
          'forme': forme,
          'horaires': [
            for (final h in heures)
              {'heure': _asApiTime(h), 'jours': ['tous']},
          ],
        },
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  static String _asApiTime(String raw) {
    final t = raw.trim();
    if (t.length >= 8 && t.contains(':')) {
      return t.length == 5 ? '$t:00' : t;
    }
    return '$t:00';
  }
}
