import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../application/health_provider.dart';

/// Écran d'accueil temporaire — valide la config Flutter ↔ API.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(apiHealthProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(AppConfig.appName)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Configuration mobile',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Socle prêt (Dio, tokens sécurisés, Riverpod). '
                'Prochaine étape : écrans auth / onboarding.',
                style: theme.textTheme.bodyLarge,
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
                  detail: err is ApiException
                      ? err.message
                      : err.toString(),
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
