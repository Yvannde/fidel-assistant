import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/constante_models.dart';
import '../domain/dashboard_models.dart';

class HomeRepository {
  HomeRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<HomeProfile> fetchProfile() async {
    try {
      final res = await _api.get<Map<String, dynamic>>('/auth/me');
      return HomeProfile.fromMeJson(res.data ?? {});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<PatientDashboard?> fetchDashboard() async {
    try {
      final res = await _api.get<Map<String, dynamic>>('/patients/me/dashboard');
      return PatientDashboard.fromJson(res.data ?? {});
    } on DioException catch (e) {
      final parsed = ApiException.fromResponse(
        e.response?.statusCode,
        e.response?.data,
      );
      if (parsed.code == 'NOT_A_PATIENT') return null;
      ApiClient.throwApi(e);
    }
  }

  Future<void> activatePatient() async {
    try {
      await _api.post<Map<String, dynamic>>('/patients/me/activate');
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<List<PriseDuJour>> listPrises({required DateTime date}) async {
    try {
      final res = await _api.get<dynamic>(
        '/patients/me/prises',
        queryParameters: {'date': _isoDate(date)},
      );
      final data = res.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => PriseDuJour.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> confirmPrise(String priseId) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/prises/$priseId/confirmer',
        data: {'canal': 'app'},
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> reportPrise(String priseId, DateTime nouvelleHeure) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/prises/$priseId/reporter',
        data: {'nouvelle_heure': nouvelleHeure.toUtc().toIso8601String()},
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<List<TraitementDetail>> listTraitements() async {
    try {
      final res = await _api.get<dynamic>('/patients/me/traitements');
      final data = res.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => TraitementDetail.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<List<CheckInEntry>> listCheckIns({required DateTime depuis}) async {
    try {
      final res = await _api.get<dynamic>(
        '/patients/me/check-in',
        queryParameters: {'depuis': _isoDate(depuis)},
      );
      final data = res.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => CheckInEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<CheckInEntry> submitCheckIn(String statut) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/patients/me/check-in',
        data: {'statut': statut},
      );
      return CheckInEntry.fromJson(res.data ?? {'statut': statut});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<List<Constante>> listConstantes({required DateTime depuis}) async {
    try {
      final res = await _api.get<dynamic>(
        '/patients/me/constantes',
        queryParameters: {'depuis': depuis.toUtc().toIso8601String()},
      );
      final data = res.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => Constante.tryParse(Map<String, dynamic>.from(e)))
          .whereType<Constante>()
          .toList();
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<ConstanteCreated> createConstante({
    required ConstanteType type,
    required Object valeur,
    required String unite,
    required DateTime mesureAt,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/patients/me/constantes',
        data: {
          'type': type.code,
          'valeur': valeur,
          'unite': unite,
          'mesure_at': mesureAt.toUtc().toIso8601String(),
          'source': 'manuel',
        },
      );
      return ConstanteCreated.fromJson(res.data ?? {});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  static String _isoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<String> createSyncCode() async {
    try {
      final res = await _api.post<Map<String, dynamic>>('/patients/me/sync-code');
      return res.data?['code'] as String? ?? '';
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<String> syncAsAidant(String code) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/aidants/me/sync',
        data: {'code': code.trim()},
      );
      return res.data?['message'] as String? ?? '';
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }
}
