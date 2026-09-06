import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/onboarding_models.dart';

class OnboardingRepository {
  OnboardingRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<OnboardingStatus> status() async {
    try {
      final res = await _api.get<Map<String, dynamic>>('/onboarding/status');
      return OnboardingStatus.fromJson(res.data ?? {});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<InfosDraft> fetchProfileDraft() async {
    try {
      final res = await _api.get<Map<String, dynamic>>('/auth/me');
      return InfosDraft.fromMeJson(res.data ?? {});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<String> saveInfos({
    required String nomComplet,
    required String dateNaissance,
    required String sexe,
    required String localisation,
    String? phone,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/onboarding/infos',
        data: {
          'nom_complet': nomComplet.trim(),
          'date_naissance': dateNaissance,
          'sexe': sexe,
          'localisation': localisation.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        },
      );
      return res.data?['onboarding_step'] as String? ?? 'besoin_suivi';
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<({String step, bool hasPatientProfile})> setBesoinSuivi({
    required bool actif,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/onboarding/besoin-suivi',
        data: {'actif': actif},
      );
      return (
        step: res.data?['onboarding_step'] as String? ?? 'besoin_suivi',
        hasPatientProfile: res.data?['has_patient_profile'] as bool? ?? actif,
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<List<MaladieCatalogItem>> listMaladies() async {
    try {
      final res = await _api.get<dynamic>('/onboarding/maladies');
      final raw = res.data;
      final list = raw is List ? raw : <dynamic>[];
      return list
          .whereType<Map>()
          .map(
            (e) => MaladieCatalogItem.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<String> saveTraitement({
    required bool enTraitement,
    List<TraitementSelection>? traitements,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/onboarding/patient/traitement',
        data: {
          'en_traitement': enTraitement,
          if (traitements != null && traitements.isNotEmpty)
            'traitements': traitements.map((t) => t.toJson()).toList(),
        },
      );
      return res.data?['onboarding_step'] as String? ?? 'patient_permissions';
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<String> savePermissions({
    required bool notificationsAccordees,
    required bool batterieExemptee,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/onboarding/patient/permissions',
        data: {
          'notifications_accordees': notificationsAccordees,
          'batterie_exemptee': batterieExemptee,
        },
      );
      return res.data?['onboarding_step'] as String? ?? 'patient_permissions';
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<String> complete() async {
    try {
      final res = await _api.post<Map<String, dynamic>>('/onboarding/complete');
      return res.data?['onboarding_step'] as String? ?? 'termine';
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }
}
