import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/language_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../l10n/app_localizations.dart';
import '../locale/locale_controller.dart';
import '../network/providers.dart';
import '../theme/app_colors.dart';

/// Notifie go_router sans recréer l'instance (évite le flash noir).
class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final _routerRefreshProvider = Provider<_RouterRefresh>((ref) {
  final refresh = _RouterRefresh();
  ref.listen<Locale?>(localeControllerProvider, (_, __) => refresh.ping());
  ref.onDispose(refresh.dispose);
  return refresh;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_routerRefreshProvider);

  return GoRouter(
    initialLocation: ref.read(localeControllerProvider) == null
        ? '/language'
        : '/login',
    refreshListenable: refresh,
    redirect: (context, state) async {
      final loc = state.matchedLocation;
      final hasLocale = ref.read(localeControllerProvider) != null;

      if (!hasLocale && loc != '/language') {
        return '/language';
      }
      if (hasLocale && loc == '/language') {
        return '/login';
      }

      if (loc == '/home') {
        final hasSession = await ref.read(tokenStorageProvider).hasSession();
        if (!hasSession) return '/login';
      }

      if (loc == '/' || loc.isEmpty) {
        if (!hasLocale) return '/language';
        final hasSession = await ref.read(tokenStorageProvider).hasSession();
        return hasSession ? '/home' : '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/language',
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: LanguageScreen(
            onContinue: (chosen) async {
              await ref
                  .read(localeControllerProvider.notifier)
                  .setLocale(chosen);
              // redirect (hasLocale + /language → /login) gère la navigation
            },
          ),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: LoginScreen(
            onLoggedIn: () => context.go('/home'),
            onSignUp: () {
              final l10n = AppLocalizations.of(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.comingSoon)),
              );
            },
            onForgotPassword: () {
              final l10n = AppLocalizations.of(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.comingSoon)),
              );
            },
          ),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: const HomeScreen(),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Text(state.error?.toString() ?? 'Not found'),
      ),
    ),
  );
});

CustomTransitionPage<void> _fadePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}
