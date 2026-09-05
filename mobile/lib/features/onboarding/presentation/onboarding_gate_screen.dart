import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_providers.dart';
import '../application/onboarding_controller.dart';

/// Point d’entrée `/onboarding` — sync step serveur puis redirection.
class OnboardingGateScreen extends ConsumerStatefulWidget {
  const OnboardingGateScreen({super.key});

  @override
  ConsumerState<OnboardingGateScreen> createState() =>
      _OnboardingGateScreenState();
}

class _OnboardingGateScreenState extends ConsumerState<OnboardingGateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  Future<void> _route() async {
    await ref.read(onboardingControllerProvider.notifier).syncFromSessionOrServer();
    if (!mounted) return;
    final step = ref.read(onboardingControllerProvider).step;
    final sessionStep = ref.read(authSessionProvider)?.onboardingStep;
    final effective = step.isNotEmpty ? step : (sessionStep ?? 'infos');

    switch (effective) {
      case 'besoin_suivi':
        context.go('/onboarding/besoin-suivi');
        return;
      case 'patient_traitement':
        context.go('/onboarding/traitement');
        return;
      case 'patient_permissions':
        context.go('/onboarding/permissions');
        return;
      case 'termine':
        context.go('/home');
        return;
      case 'infos':
      default:
        context.go('/onboarding/infos');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
