import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Brouillon mot de passe oublié — email + temp_token après OTP validé.
class ForgotPasswordDraft {
  const ForgotPasswordDraft({this.email, this.tempToken});

  final String? email;
  final String? tempToken;

  ForgotPasswordDraft copyWith({String? email, String? tempToken}) {
    return ForgotPasswordDraft(
      email: email ?? this.email,
      tempToken: tempToken ?? this.tempToken,
    );
  }
}

class ForgotPasswordController extends StateNotifier<ForgotPasswordDraft> {
  ForgotPasswordController() : super(const ForgotPasswordDraft());

  void setEmail(String email) {
    state = state.copyWith(email: email.trim().toLowerCase());
  }

  void setTempToken(String token) {
    state = state.copyWith(tempToken: token);
  }

  void reset() {
    state = const ForgotPasswordDraft();
  }
}

final forgotPasswordDraftProvider =
    StateNotifierProvider<ForgotPasswordController, ForgotPasswordDraft>((ref) {
  return ForgotPasswordController();
});
