class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.sessionId,
    required this.onboardingStep,
    required this.hasPatientProfile,
    required this.isAidant,
    this.isNewUser = false,
    this.needsCgu = false,
    this.needsConsentementSante = false,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String sessionId;
  final String onboardingStep;
  final bool hasPatientProfile;
  final bool isAidant;
  final bool isNewUser;
  final bool needsCgu;
  final bool needsConsentementSante;

  bool get needsLegalAcceptance => needsCgu || needsConsentementSante;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 0,
      sessionId: json['session_id']?.toString() ?? '',
      onboardingStep: json['onboarding_step'] as String? ?? 'infos',
      hasPatientProfile: json['has_patient_profile'] as bool? ?? false,
      isAidant: json['is_aidant'] as bool? ?? false,
      isNewUser: json['is_new_user'] as bool? ?? false,
      needsCgu: json['needs_cgu'] as bool? ?? false,
      needsConsentementSante:
          json['needs_consentement_sante'] as bool? ?? false,
    );
  }

  AuthSession copyWith({
    bool? needsCgu,
    bool? needsConsentementSante,
  }) {
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
      sessionId: sessionId,
      onboardingStep: onboardingStep,
      hasPatientProfile: hasPatientProfile,
      isAidant: isAidant,
      isNewUser: isNewUser,
      needsCgu: needsCgu ?? this.needsCgu,
      needsConsentementSante:
          needsConsentementSante ?? this.needsConsentementSante,
    );
  }
}
