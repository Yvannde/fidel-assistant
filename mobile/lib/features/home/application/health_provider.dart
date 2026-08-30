import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';

/// Ping `GET /health` pour valider la config réseau au boot.
final apiHealthProvider = FutureProvider.autoDispose<String>((ref) async {
  final client = ref.watch(apiClientProvider);
  try {
    final res = await client.get<Map<String, dynamic>>(
      '/health',
      skipAuth: true,
    );
    final data = res.data;
    final status = data?['status']?.toString() ?? 'ok';
    final service = data?['service']?.toString() ?? '';
    return service.isEmpty ? status : '$status — $service';
  } on DioException catch (e) {
    ApiClient.throwApi(e);
  }
});
