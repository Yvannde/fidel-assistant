import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

      if (loc == '/home' || loc == '/auth/google-legal') {
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
            onLoggedIn: () => context.go('/home'),
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
        path: '/home',
        pageBuilder: (context, state) => _softPage(
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
