import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/premium.dart';
import '../application/home_controller.dart';
import 'home_care_screen.dart';
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
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DawnBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: IndexedStack(
          index: _index,
          children: const [
            HomeDashboardScreen(),
            HomeCareScreen(),
            HomeNetworkScreen(),
            HomeProfileScreen(),
          ],
        ),
        bottomNavigationBar: FidelNavBar(
          index: _index,
          onChanged: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}
