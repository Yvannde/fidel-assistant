import 'package:flutter_test/flutter_test.dart';

import 'package:fidel_assistant/core/storage/session_meta.dart';
import 'package:fidel_assistant/features/auth/domain/auth_session.dart';

void main() {
  test('SessionMeta round-trip encode/decode', () {
    const session = AuthSession(
      accessToken: 'a',
      refreshToken: 'r',
      expiresIn: 3600,
      sessionId: 's',
      onboardingStep: 'termine',
      hasPatientProfile: true,
      isAidant: false,
    );
    final meta = SessionMeta.fromSession(session);
    final raw = meta.encode();
    final decoded = SessionMeta.decode(raw);
    expect(decoded?.onboardingStep, 'termine');
    expect(decoded?.hasPatientProfile, isTrue);

    final restored = decoded!.applyTo(
      accessToken: 'a',
      refreshToken: 'r',
      sessionId: 's',
    );
    expect(restored.onboardingStep, 'termine');
    expect(restored.hasPatientProfile, isTrue);
  });
}
