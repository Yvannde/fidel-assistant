import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../domain/auth_session.dart';

/// Redirection post-auth (login email / Google).
void navigateAfterAuth(BuildContext context, AuthSession session) {
  if (session.needsLegalAcceptance) {
    context.go('/auth/google-legal');
    return;
  }
  if (session.isNewUser && session.onboardingStep != 'termine') {
    context.go('/register/account-success');
    return;
  }
  context.go('/home');
}
