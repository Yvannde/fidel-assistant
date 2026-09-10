import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network_status.dart';
import 'sync_engine.dart';

/// Probe périodique + flush gated sur resume / timer (Phase 2).
class SyncLifecycleBinder extends ConsumerStatefulWidget {
  const SyncLifecycleBinder({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SyncLifecycleBinder> createState() =>
      _SyncLifecycleBinderState();
}

class _SyncLifecycleBinderState extends ConsumerState<SyncLifecycleBinder>
    with WidgetsBindingObserver {
  static const _periodicFlush = Duration(minutes: 7);

  Timer? _periodic;
  NetworkStatus? _net;
  NetworkLinkState? _lastState;

  void _onNetworkChanged() {
    final net = _net;
    if (net == null) return;
    final was = _lastState;
    _lastState = net.state;
    if (was != NetworkLinkState.online &&
        net.state == NetworkLinkState.online) {
      _scheduledFlush();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final net = ref.read(networkStatusProvider);
      _net = net;
      _lastState = net.state;
      net.addListener(_onNetworkChanged);
      net.startProbing();
      _periodic = Timer.periodic(_periodicFlush, (_) => _scheduledFlush());
      _scheduledFlush();
    });
  }

  void _scheduledFlush() {
    final net = ref.read(networkStatusProvider);
    if (!net.allowScheduledFlush()) return;
    unawaited(ref.read(syncEngineProvider).flush());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final net = ref.read(networkStatusProvider);
    if (state == AppLifecycleState.resumed) {
      unawaited(net.onAppResumed());
      _scheduledFlush();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      net.onAppPaused();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _periodic?.cancel();
    _net?.removeListener(_onNetworkChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
