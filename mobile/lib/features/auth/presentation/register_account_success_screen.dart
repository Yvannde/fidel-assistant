import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import 'widgets/auth_success_screen.dart';

class RegisterAccountSuccessScreen extends StatelessWidget {
  const RegisterAccountSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AuthSuccessScreen(
      title: l10n.successAccountTitle,
      subtitle: l10n.successAccountSubtitle,
      ctaLabel: l10n.successAccountCta,
      onContinue: () => context.go('/home'),
    );
  }
}
