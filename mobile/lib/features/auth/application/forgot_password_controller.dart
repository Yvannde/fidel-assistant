import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Brouillon mot de passe oublié — email + code OTP.
class ForgotPasswordDraft {
  const ForgotPasswordDraft({this.email, this.code});

  final String? email;
  final String? code;

  ForgotPasswordDraft copyWith({String? email, String? code}) {
    return ForgotPasswordDraft(
      email: email ?? this.email,
      code: code ?? this.code,
    );
  }
}

class ForgotPasswordController extends StateNotifier<ForgotPasswordDraft> {
  ForgotPasswordController() : super(const ForgotPasswordDraft());

  void setEmail(String email) {
    state = state.copyWith(email: email.trim().toLowerCase());
  }

  void setCode(String code) {
    state = state.copyWith(code: code.trim());
  }

  void reset() {
    state = const ForgotPasswordDraft();
  }
}

final forgotPasswordDraftProvider =
    StateNotifierProvider<ForgotPasswordController, ForgotPasswordDraft>((ref) {
  return ForgotPasswordController();
});
