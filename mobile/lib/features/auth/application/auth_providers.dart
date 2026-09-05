import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../data/auth_repository.dart';
import '../domain/auth_session.dart';

export 'registration_controller.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final authSessionProvider =
    StateNotifierProvider<AuthSessionController, AuthSession?>((ref) {
  return AuthSessionController(ref);
});

class AuthSessionController extends StateNotifier<AuthSession?> {
  AuthSessionController(this._ref) : super(null);

  final Ref _ref;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final session = await _ref.read(authRepositoryProvider).login(
          email: email,
          password: password,
        );
    state = session;
    return session;
  }

  Future<void> logout() async {
    await _ref.read(authRepositoryProvider).logout();
    state = null;
  }

  void clearLocal() {
    state = null;
  }
}
