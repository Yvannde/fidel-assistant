import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../domain/auth_session.dart';

/// Redirection post-auth (login email / Google / succès compte).
void navigateAfterAuth(BuildContext context, AuthSession session) {
  if (session.needsLegalAcceptance) {
    context.go('/auth/google-legal');
    return;
  }
  if (session.onboardingStep != 'termine') {
    context.go('/onboarding');
    return;
  }
  context.go('/home');
}

void navigateAfterAccountReady(BuildContext context) {
  context.go('/onboarding');
}
