class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.sessionId,
    required this.onboardingStep,
    required this.hasPatientProfile,
    required this.isAidant,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String sessionId;
  final String onboardingStep;
  final bool hasPatientProfile;
  final bool isAidant;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 0,
      sessionId: json['session_id'] as String? ?? '',
      onboardingStep: json['onboarding_step'] as String? ?? 'infos',
      hasPatientProfile: json['has_patient_profile'] as bool? ?? false,
      isAidant: json['is_aidant'] as bool? ?? false,
    );
  }
}
