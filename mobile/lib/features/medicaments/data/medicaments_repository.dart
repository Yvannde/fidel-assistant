import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import '../../onboarding/domain/onboarding_models.dart';

final medicamentsRepositoryProvider = Provider<MedicamentsRepository>((ref) {
  return MedicamentsRepository(apiClient: ref.watch(apiClientProvider));
});

class ConfiguredMedicament {
  const ConfiguredMedicament({
    required this.id,
    required this.traitementId,
    required this.nom,
    required this.dosage,
    this.stockRestant,
    this.seuilAlerteStock,
  });

  final String id;
  final String traitementId;
  final String nom;
  final String dosage;
  final int? stockRestant;
  final int? seuilAlerteStock;

  factory ConfiguredMedicament.fromJson(Map<String, dynamic> json) {
    return ConfiguredMedicament(
      id: json['id']?.toString() ?? '',
      traitementId: json['patient_traitement_id']?.toString() ?? '',
      nom: json['nom'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      stockRestant: (json['stock_restant'] as num?)?.toInt(),
      seuilAlerteStock: (json['seuil_alerte_stock'] as num?)?.toInt(),
    );
  }

  ConfiguredMedicament copyWith({
    int? stockRestant,
    int? seuilAlerteStock,
    bool clearStock = false,
    bool clearSeuil = false,
  }) {
    return ConfiguredMedicament(
      id: id,
      traitementId: traitementId,
      nom: nom,
      dosage: dosage,
      stockRestant: clearStock ? null : (stockRestant ?? this.stockRestant),
      seuilAlerteStock:
          clearSeuil ? null : (seuilAlerteStock ?? this.seuilAlerteStock),
    );
  }
}

class StockUpdateResult {
  const StockUpdateResult({
    required this.stockRestant,
    required this.alerteDeclenchee,
  });

  final int stockRestant;
  final bool alerteDeclenchee;
}

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
    DateTime? dateDebut,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/patients/me/traitements',
        data: {
          'maladie_id': maladieId,
          'phase': phase,
          if (dateDebut != null)
            'date_debut':
                '${dateDebut.year.toString().padLeft(4, '0')}-'
                '${dateDebut.month.toString().padLeft(2, '0')}-'
                '${dateDebut.day.toString().padLeft(2, '0')}',
        },
      );
      return res.data?['id']?.toString() ?? '';
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<List<ConfiguredMedicament>> listMedicaments({
    String? traitementId,
  }) async {
    try {
      final res = await _api.get<dynamic>('/patients/me/medicaments');
      final data = res.data;
      if (data is! List) return const [];
      final all = data
          .whereType<Map>()
          .map((e) => ConfiguredMedicament.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (traitementId == null || traitementId.isEmpty) return all;
      return all.where((m) => m.traitementId == traitementId).toList();
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> createMedicament({
    required String traitementId,
    required String nom,
    required String dosage,
    String forme = 'comprime',
    String? priseAvecRepas,
    required List<String> heures,
    List<String> jours = const ['tous'],
    int? stockRestant,
    int? seuilAlerteStock,
  }) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/traitements/$traitementId/medicaments',
        data: {
          'nom': nom.trim(),
          'dosage': dosage.trim(),
          'forme': forme,
          if (priseAvecRepas != null) 'prise_avec_repas': priseAvecRepas,
          if (stockRestant != null) 'stock_restant': stockRestant,
          if (seuilAlerteStock != null) 'seuil_alerte_stock': seuilAlerteStock,
          'horaires': [
            for (final h in heures)
              {
                'heure': _asApiTime(h),
                'jours': jours,
              },
          ],
        },
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<StockUpdateResult> updateStock({
    required String medicamentId,
    required int stockRestant,
  }) async {
    try {
      final res = await _api.patch<Map<String, dynamic>>(
        '/medicaments/$medicamentId/stock',
        data: {'stock_restant': stockRestant},
      );
      final data = res.data ?? {};
      return StockUpdateResult(
        stockRestant: (data['stock_restant'] as num?)?.toInt() ?? stockRestant,
        alerteDeclenchee: data['alerte_declenchee'] as bool? ?? false,
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> updateSeuil({
    required String medicamentId,
    required int seuilAlerteStock,
  }) async {
    try {
      await _api.patch<Map<String, dynamic>>(
        '/medicaments/$medicamentId',
        data: {'seuil_alerte_stock': seuilAlerteStock},
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
