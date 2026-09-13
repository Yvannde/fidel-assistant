import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/premium.dart';
import '../../../services/sync_engine.dart';
import '../../auth/application/auth_providers.dart';
import '../application/cercle_controller.dart';
import '../application/home_controller.dart';
import 'health_screen.dart';
import 'home_dashboard_screen.dart';
import 'home_network_screen.dart';
import 'home_profile_screen.dart';
import 'widgets/fidel_nav_bar.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  var _emptyRetryDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeControllerProvider.notifier).load();
      ref.read(cercleControllerProvider.notifier).load(force: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(homeControllerProvider.notifier).ensureLoaded();
      ref.read(cercleControllerProvider.notifier).load(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(syncPullTickProvider, (prev, next) {
      if (prev == next) return;
      ref.read(homeControllerProvider.notifier).reloadProjection();
    });

    ref.listen(authSessionProvider, (prev, next) {
      if (next == null) return;
      if (prev?.hasPatientProfile == next.hasPatientProfile &&
          prev?.sessionId == next.sessionId &&
          prev?.isAidant == next.isAidant) {
        return;
      }
      _emptyRetryDone = false;
      ref.read(homeControllerProvider.notifier).ensureLoaded();
      ref.read(cercleControllerProvider.notifier).load(force: true);
    });

    ref.listen(homeControllerProvider, (prev, next) {
      final session = ref.read(authSessionProvider);
      final needsData = session?.hasPatientProfile == true ||
          next.profile?.hasPatientProfile == true;
      if (prev?.profile == null && next.profile != null) {
        ref.read(cercleControllerProvider.notifier).load(force: true);
      }
      if (!needsData) return;
      if (next.loading) return;
      if (next.dashboard != null) {
        _emptyRetryDone = false;
        return;
      }
      if (_emptyRetryDone) return;
      if (prev?.loading == true && !next.loading) {
        _emptyRetryDone = true;
        ref.read(homeControllerProvider.notifier).ensureLoaded();
      }
    });

    ref.listen(homeTabIndexProvider, (prev, next) {
      if (next == 2) {
        ref.read(cercleControllerProvider.notifier).load(force: true);
      }
    });

    final index = ref.watch(homeTabIndexProvider);
    return DawnBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: IndexedStack(
          index: index,
          children: const [
            HomeDashboardScreen(),
            HealthScreen(),
            HomeNetworkScreen(),
            HomeProfileScreen(),
          ],
        ),
        bottomNavigationBar: FidelNavBar(
          index: index,
          onChanged: (i) =>
              ref.read(homeTabIndexProvider.notifier).state = i,
        ),
      ),
    );
  }
}
