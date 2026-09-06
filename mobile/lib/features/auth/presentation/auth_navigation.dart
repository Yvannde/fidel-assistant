import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../domain/auth_session.dart';

String routeAfterAuth(AuthSession session) {
  if (session.needsLegalAcceptance) return '/auth/google-legal';
  if (session.onboardingStep != 'termine') return '/onboarding';
  return '/home';
}

/// Redirection post-auth (login email / Google / succès compte).
void navigateAfterAuth(BuildContext context, AuthSession session) {
  context.go(routeAfterAuth(session));
}

void navigateAfterAccountReady(BuildContext context) {
  context.go('/onboarding');
}
