import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

enum RefreshResult { success, networkError, rejected }

/// Client HTTP central — intercepteur Bearer + refresh automatique.
class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    Dio? dio,
    Dio? refreshDio,
    void Function(Headers headers)? onResponseHeaders,
  })  : _tokenStorage = tokenStorage,
        _onResponseHeaders = onResponseHeaders,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiV1Base,
                connectTimeout: AppConfig.connectTimeout,
                receiveTimeout: AppConfig.receiveTimeout,
                headers: const {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            ),
        _refreshDio = refreshDio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiV1Base,
                connectTimeout: AppConfig.connectTimeout,
                receiveTimeout: AppConfig.receiveTimeout,
                headers: const {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            ) {
    void captureDate(Response<dynamic> response) {
      _onResponseHeaders?.call(response.headers);
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          captureDate(response);
          handler.next(response);
        },
      ),
    );
    _refreshDio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          captureDate(response);
          handler.next(response);
        },
      ),
    );
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final skipAuth = options.extra['skipAuth'] == true;
          if (!skipAuth) {
            final token = await _tokenStorage.readAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode != 401) {
            handler.next(error);
            return;
          }
          final req = error.requestOptions;
          if (req.extra['skipAuth'] == true || req.extra['_retried'] == true) {
            handler.next(error);
            return;
          }

          final refreshed = await _tryRefresh();
          if (refreshed == RefreshResult.rejected) {
            await _tokenStorage.clear();
            handler.next(error);
            return;
          }
          if (refreshed != RefreshResult.success) {
            handler.next(error);
            return;
          }

          final token = await _tokenStorage.readAccessToken();
          req.headers['Authorization'] = 'Bearer $token';
          req.extra['_retried'] = true;
          try {
            final response = await _dio.fetch<dynamic>(req);
            handler.resolve(response);
          } on DioException catch (e) {
            handler.next(e);
          }
        },
      ),
    );
  }

  final TokenStorage _tokenStorage;
  final Dio _dio;
  final Dio _refreshDio;
  final void Function(Headers headers)? _onResponseHeaders;

  Dio get raw => _dio;

  Future<RefreshResult> _tryRefresh() async {
    final refresh = await _tokenStorage.readRefreshToken();
    if (refresh == null || refresh.isEmpty) return RefreshResult.rejected;
    try {
      final res = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refresh},
      );
      final access = res.data?['access_token'] as String?;
      if (access == null || access.isEmpty) return RefreshResult.rejected;
      await _tokenStorage.saveAccessToken(access);
      return RefreshResult.success;
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      if (status == 401 || status == 403) return RefreshResult.rejected;
      return RefreshResult.networkError;
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool skipAuth = false,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: Options(extra: {'skipAuth': skipAuth}),
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    bool skipAuth = false,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      options: Options(extra: {'skipAuth': skipAuth}),
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    bool skipAuth = false,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      options: Options(extra: {'skipAuth': skipAuth}),
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    bool skipAuth = false,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      options: Options(extra: {'skipAuth': skipAuth}),
    );
  }

  /// Convertit une [DioException] en [ApiException] lisible.
  static Never throwApi(DioException e) {
    throw ApiException.fromResponse(e.response?.statusCode, e.response?.data);
  }
}
