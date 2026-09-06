import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
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
