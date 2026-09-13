import 'dart:convert';

import '../../features/auth/domain/auth_session.dart';

/// Métadonnées session persistées localement pour le boot offline.
class SessionMeta {
  const SessionMeta({
    required this.onboardingStep,
    required this.hasPatientProfile,
    required this.isAidant,
    this.needsCgu = false,
    this.needsConsentementSante = false,
  });

  final String onboardingStep;
  final bool hasPatientProfile;
  final bool isAidant;
  final bool needsCgu;
  final bool needsConsentementSante;

  factory SessionMeta.fromSession(AuthSession session) {
    return SessionMeta(
      onboardingStep: session.onboardingStep,
      hasPatientProfile: session.hasPatientProfile,
      isAidant: session.isAidant,
      needsCgu: session.needsCgu,
      needsConsentementSante: session.needsConsentementSante,
    );
  }

  AuthSession applyTo({
    required String accessToken,
    required String refreshToken,
    required String sessionId,
  }) {
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: 0,
      sessionId: sessionId,
      onboardingStep: onboardingStep,
      hasPatientProfile: hasPatientProfile,
      isAidant: isAidant,
      needsCgu: needsCgu,
      needsConsentementSante: needsConsentementSante,
    );
  }

  Map<String, dynamic> toJson() => {
        'onboarding_step': onboardingStep,
        'has_patient_profile': hasPatientProfile,
        'is_aidant': isAidant,
        'needs_cgu': needsCgu,
        'needs_consentement_sante': needsConsentementSante,
      };

  factory SessionMeta.fromJson(Map<String, dynamic> json) {
    return SessionMeta(
      onboardingStep: json['onboarding_step'] as String? ?? 'infos',
      hasPatientProfile: json['has_patient_profile'] as bool? ?? false,
      isAidant: json['is_aidant'] as bool? ?? false,
      needsCgu: json['needs_cgu'] as bool? ?? false,
      needsConsentementSante:
          json['needs_consentement_sante'] as bool? ?? false,
    );
  }

  static SessionMeta? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return SessionMeta.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  String encode() => jsonEncode(toJson());
}
