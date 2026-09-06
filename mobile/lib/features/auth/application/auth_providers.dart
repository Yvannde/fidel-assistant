import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../data/auth_repository.dart';
import '../domain/auth_session.dart';

export 'forgot_password_controller.dart';
export 'registration_controller.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

/// Session relue depuis le Keystore + `/auth/me` dans [main] avant `runApp`.
final restoredAuthSessionProvider = Provider<AuthSession?>((ref) => null);

final authSessionProvider =
    StateNotifierProvider<AuthSessionController, AuthSession?>((ref) {
  return AuthSessionController(ref, ref.read(restoredAuthSessionProvider));
});

class AuthSessionController extends StateNotifier<AuthSession?> {
  AuthSessionController(this._ref, [AuthSession? restored]) : super(restored);

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

  Future<AuthSession> loginWithGoogle({
    required String langue,
    String? fuseauHoraire,
  }) async {
    final session = await _ref.read(authRepositoryProvider).loginWithGoogle(
          langue: langue,
          fuseauHoraire: fuseauHoraire,
        );
    state = session;
    return session;
  }

  void markLegalAccepted() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      needsCgu: false,
      needsConsentementSante: false,
    );
  }

  void updateOnboarding({
    required String step,
    bool? hasPatientProfile,
  }) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      onboardingStep: step,
      hasPatientProfile: hasPatientProfile,
    );
  }

  Future<void> logout() async {
    await _ref.read(authRepositoryProvider).logout();
    state = null;
  }

  void clearLocal() {
    state = null;
  }
}
