import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/domain/auth_session.dart';
import '../../features/auth/presentation/auth_navigation.dart';
import '../../features/auth/presentation/forgot_password_email_screen.dart';
import '../../features/auth/presentation/forgot_password_otp_screen.dart';
import '../../features/auth/presentation/forgot_password_reset_screen.dart';
import '../../features/auth/presentation/google_legal_screen.dart';
import '../../features/auth/presentation/language_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_account_success_screen.dart';
import '../../features/auth/presentation/register_email_screen.dart';
import '../../features/auth/presentation/register_legal_screen.dart';
import '../../features/auth/presentation/register_otp_screen.dart';
import '../../features/auth/presentation/register_password_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_besoin_suivi_screen.dart';
import '../../features/onboarding/presentation/onboarding_gate_screen.dart';
import '../../features/onboarding/presentation/onboarding_infos_screen.dart';
import '../../features/onboarding/presentation/onboarding_permissions_screen.dart';
import '../../features/onboarding/presentation/onboarding_traitement_screen.dart';
import '../locale/locale_controller.dart';
import '../network/providers.dart';

/// Notifie go_router sans recréer l'instance (évite le flash noir).
class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final _routerRefreshProvider = Provider<_RouterRefresh>((ref) {
  final refresh = _RouterRefresh();
  ref.listen<Locale?>(localeControllerProvider, (_, __) => refresh.ping());
  ref.listen<AuthSession?>(authSessionProvider, (_, __) => refresh.ping());
  ref.onDispose(refresh.dispose);
  return refresh;
});

String _bootLocation({required bool hasLocale, AuthSession? session}) {
  if (!hasLocale) return '/language';
  if (session != null) return routeAfterAuth(session);
  return '/login';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_routerRefreshProvider);

  return GoRouter(
    initialLocation: _bootLocation(
      hasLocale: ref.read(localeControllerProvider) != null,
      session: ref.read(authSessionProvider),
    ),
    refreshListenable: refresh,
    redirect: (context, state) async {
      final loc = state.matchedLocation;
      final hasLocale = ref.read(localeControllerProvider) != null;
      final session = ref.read(authSessionProvider);

      if (!hasLocale && loc != '/language') {
        return '/language';
      }
      if (hasLocale && loc == '/language') {
        return session != null ? routeAfterAuth(session) : '/login';
      }

      final needsSession = loc == '/home' ||
          loc == '/auth/google-legal' ||
          loc.startsWith('/onboarding');
      if (needsSession) {
        final hasSession = await ref.read(tokenStorageProvider).hasSession();
        if (!hasSession) return '/login';
      }

      if (loc == '/login' && session != null) {
        return routeAfterAuth(session);
      }

      if (loc == '/home' &&
          session != null &&
          session.onboardingStep != 'termine') {
        return '/onboarding';
      }

      if (loc == '/' || loc.isEmpty) {
        if (!hasLocale) return '/language';
        if (session != null) return routeAfterAuth(session);
        final hasSession = await ref.read(tokenStorageProvider).hasSession();
        return hasSession ? '/onboarding' : '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/language',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: LanguageScreen(
            onContinue: (chosen) async {
              await ref
                  .read(localeControllerProvider.notifier)
                  .setLocale(chosen);
            },
          ),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: LoginScreen(
            onLoggedIn: () {
              final session = ref.read(authSessionProvider);
              if (session != null) {
                navigateAfterAuth(context, session);
              } else {
                context.go('/onboarding');
              }
            },
            onSignUp: () => context.push('/register'),
            onForgotPassword: () => context.push('/forgot-password'),
          ),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const ForgotPasswordEmailScreen(),
        ),
      ),
      GoRoute(
        path: '/forgot-password/otp',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const ForgotPasswordOtpScreen(),
        ),
      ),
      GoRoute(
        path: '/forgot-password/reset',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const ForgotPasswordResetScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const RegisterEmailScreen(),
        ),
      ),
      GoRoute(
        path: '/register/otp',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const RegisterOtpScreen(),
        ),
      ),
      GoRoute(
        path: '/register/password',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const RegisterPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/register/legal',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const RegisterLegalScreen(),
        ),
      ),
      GoRoute(
        path: '/auth/google-legal',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const GoogleLegalScreen(),
        ),
      ),
      GoRoute(
        path: '/register/account-success',
        pageBuilder: (context, state) => _successPage(
          state: state,
          child: const RegisterAccountSuccessScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const OnboardingGateScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding/infos',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const OnboardingInfosScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding/besoin-suivi',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const OnboardingBesoinSuiviScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding/traitement',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const OnboardingTraitementScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding/permissions',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const OnboardingPermissionsScreen(),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const HomeScreen(),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Text(state.error?.toString() ?? 'Not found'),
      ),
    ),
  );
});

CustomTransitionPage<void> _softPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

CustomTransitionPage<void> _successPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 560),
    reverseTransitionDuration: const Duration(milliseconds: 360),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
