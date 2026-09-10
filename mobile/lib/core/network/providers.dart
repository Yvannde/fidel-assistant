import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/server_clock.dart';
import '../storage/token_storage.dart';
import 'api_client.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final clock = ref.watch(serverClockProvider);
  return ApiClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    onResponseHeaders: (headers) {
      clock.observeHttpDate(headers.value('date'));
    },
  );
});
