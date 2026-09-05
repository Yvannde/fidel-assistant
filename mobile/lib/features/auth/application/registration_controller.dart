import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Brouillon d'inscription — email + temp_token + mdp (auto-login après CGU).
class RegistrationDraft {
  const RegistrationDraft({
    this.email,
    this.tempToken,
    this.password,
  });

  final String? email;
  final String? tempToken;
  final String? password;

  RegistrationDraft copyWith({
    String? email,
    String? tempToken,
    String? password,
    bool clearPassword = false,
  }) {
    return RegistrationDraft(
      email: email ?? this.email,
      tempToken: tempToken ?? this.tempToken,
      password: clearPassword ? null : (password ?? this.password),
    );
  }
}

class RegistrationController extends StateNotifier<RegistrationDraft> {
  RegistrationController() : super(const RegistrationDraft());

  void setEmail(String email) {
    state = state.copyWith(email: email.trim().toLowerCase());
  }

  void setTempToken(String token) {
    state = state.copyWith(tempToken: token);
  }

  void setPassword(String password) {
    state = state.copyWith(password: password);
  }

  void clearSensitive() {
    state = state.copyWith(clearPassword: true);
  }

  void reset() {
    state = const RegistrationDraft();
  }
}

final registrationDraftProvider =
    StateNotifierProvider<RegistrationController, RegistrationDraft>((ref) {
  return RegistrationController();
});
