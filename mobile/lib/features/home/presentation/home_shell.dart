import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/premium.dart';
import '../../../services/sync_engine.dart';
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

class _HomeShellState extends ConsumerState<HomeShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(syncPullTickProvider, (prev, next) {
      if (prev == next) return;
      ref.read(homeControllerProvider.notifier).reloadProjection();
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
