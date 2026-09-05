import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_providers.dart';
import '../../onboarding/application/onboarding_controller.dart';
import '../application/health_provider.dart';

/// Accueil temporaire — valide Flutter ↔ API + session.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureOnboardingDone());
  }

  Future<void> _ensureOnboardingDone() async {
    final session = ref.read(authSessionProvider);
    if (session != null && session.onboardingStep == 'termine') return;
    if (session != null && session.onboardingStep != 'termine') {
      if (mounted) context.go('/onboarding');
      return;
    }
    try {
      await ref
          .read(onboardingControllerProvider.notifier)
          .syncFromSessionOrServer();
      if (!mounted) return;
      final step = ref.read(onboardingControllerProvider).step;
      if (step != 'termine') {
        context.go('/onboarding');
      }
    } catch (_) {
      // Sans session mémoire et API KO : on tente le gate (reprise).
      if (mounted) context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final health = ref.watch(apiHealthProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(authSessionProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            child: Text(l10n.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppConfig.appName,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.onboardingDoneToast,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Text('API', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              SelectableText(
                AppConfig.apiV1Base,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 16),
              health.when(
                data: (msg) => _StatusCard(
                  ok: true,
                  title: 'Backend joignable',
                  detail: msg,
                ),
                loading: () => const _StatusCard(
                  ok: null,
                  title: 'Connexion au backend…',
                  detail: 'GET /api/v1/health',
                ),
                error: (err, _) => _StatusCard(
                  ok: false,
                  title: 'Backend injoignable',
                  detail: err is ApiException ? err.message : err.toString(),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => ref.invalidate(apiHealthProvider),
                child: const Text('Retester la connexion'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.ok,
    required this.title,
    required this.detail,
  });

  final bool? ok;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color bg;
    final Color fg;
    if (ok == true) {
      bg = scheme.primaryContainer;
      fg = scheme.onPrimaryContainer;
    } else if (ok == false) {
      bg = scheme.errorContainer;
      fg = scheme.onErrorContainer;
    } else {
      bg = scheme.surfaceContainerHighest;
      fg = scheme.onSurface;
    }

    return Semantics(
      liveRegion: true,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(detail, style: TextStyle(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}
