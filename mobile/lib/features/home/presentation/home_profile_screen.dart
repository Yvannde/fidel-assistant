import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/premium.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_providers.dart';
import '../../../core/theme/theme_controller.dart';

class HomeProfileScreen extends ConsumerWidget {
  const HomeProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeControllerProvider);
    final padTop = 12 + MediaQuery.paddingOf(context).top;

    return ListView(
      padding: EdgeInsets.fromLTRB(22, padTop, 22, Premium.navClearance),
      children: [
        Text(
          l10n.navYou,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 20),
        PremiumCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                title: Text(l10n.homeThemeLabel),
                subtitle: Text(_themeLabel(l10n, themeMode)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _cycleTheme(ref, themeMode),
              ),
              const Divider(height: 1),
              ListTile(
                title: Text(l10n.logout),
                textColor: Theme.of(context).colorScheme.error,
                onTap: () async {
                  await ref.read(authSessionProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _themeLabel(AppLocalizations l10n, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => l10n.homeThemeLight,
      ThemeMode.dark => l10n.homeThemeDark,
      ThemeMode.system => l10n.homeThemeSystem,
    };
  }

  Future<void> _cycleTheme(WidgetRef ref, ThemeMode current) async {
    final next = switch (current) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    await ref.read(themeControllerProvider.notifier).setThemeMode(next);
  }
}
