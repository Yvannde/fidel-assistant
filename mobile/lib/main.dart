import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/app_config.dart';
import 'core/locale/locale_controller.dart';
import 'core/network/api_client.dart';
import 'core/network/providers.dart';
import 'core/router/app_router.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/home/data/home_repository.dart';
import 'features/home/presentation/alarm_ring_screen.dart';
import 'l10n/app_localizations.dart';
import 'services/live_alarm_test.dart';
import 'services/pending_prise_sync_queue.dart';
import 'services/reminder_sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  // DateFormat (Accueil / Soins) exige les symboles FR+EN avant tout switch.
  await ensureDateFormatting('fr');
  await ensureDateFormatting('en');
  final prefs = await SharedPreferences.getInstance();
  final tokens = TokenStorage();
  final api = ApiClient(tokenStorage: tokens);
  final restored = await AuthRepository(
    apiClient: api,
    tokenStorage: tokens,
  ).restoreSession();

  await Alarm.init();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      tokenStorageProvider.overrideWithValue(tokens),
      restoredAuthSessionProvider.overrideWithValue(restored),
    ],
  );

  final alarms = container.read(reminderAlarmServiceProvider);
  await alarms.init(
    onResponse: (response) {
      unawaited(ReminderActionDispatcher(container).handle(response));
    },
  );
  // Réarme H0 / préavis / mark depuis le cache local (reboot / kill),
  // sans attendre le load home ni le réseau.
  try {
    await alarms.restoreFromLocalCache();
  } catch (e, st) {
    debugPrint('main: restoreFromLocalCache failed: $e\n$st');
  }
  unawaited(maybeRunLiveAlarmTest(alarms));

  if (restored != null) {
    unawaited(
      PendingPriseSyncQueue(prefs).flush(HomeRepository(apiClient: api)),
    );
  }

  final router = container.read(appRouterProvider);
  bindAlarmRingingNavigation(router);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FidelApp(),
    ),
  );
}

class FidelApp extends ConsumerWidget {
  const FidelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final themeMode = ref.watch(themeControllerProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 350),
      themeAnimationCurve: Curves.easeOutCubic,
      locale: locale ?? const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        // Fond bleu pendant les transitions (évite le flash noir Android).
        return ColoredBox(
          color: AppColors.primary,
          child: MediaQuery(
            data: media.copyWith(
              textScaler: media.textScaler.clamp(
                minScaleFactor: 1.0,
                maxScaleFactor: 1.6,
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
