import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/providers.dart';

enum NetworkLinkState { offline, degraded, online }

/// Hystérésis + probe HTTP + circuit breaker (Phase 2).
///
/// Ne bascule jamais sur un seul signal OS — uniquement probe `/health`
/// et retours sync.
class NetworkStatus extends ChangeNotifier {
  NetworkStatus({
    required Future<bool> Function() probe,
    DateTime Function()? now,
    this.stabilityWindow = const Duration(seconds: 5),
    this.probeInterval = const Duration(seconds: 18),
    this.syncCooldown = const Duration(seconds: 30),
    this.breakerOpenDuration = const Duration(minutes: 2),
    this.failsToDegraded = 3,
    this.oksToOnline = 2,
    this.fails5xxToOpen = 5,
  })  : _probe = probe,
        _now = now ?? DateTime.now;

  final Future<bool> Function() _probe;
  final DateTime Function() _now;

  final Duration stabilityWindow;
  final Duration probeInterval;
  final Duration syncCooldown;
  final Duration breakerOpenDuration;
  final int failsToDegraded;
  final int oksToOnline;
  final int fails5xxToOpen;

  NetworkLinkState _state = NetworkLinkState.offline;
  int _consecutiveOk = 0;
  int _consecutiveFail = 0;
  DateTime? _firstOkInSeries;
  int _consecutive5xx = 0;
  DateTime? _breakerOpenUntil;
  bool _halfOpen = false;
  DateTime? _lastScheduledFlushAt;
  Timer? _probeTimer;
  bool _probing = false;
  bool _disposed = false;

  NetworkLinkState get state => _state;

  bool get isHalfOpen => _halfOpen;

  bool get circuitOpen {
    final until = _breakerOpenUntil;
    if (until == null) return false;
    if (_now().isBefore(until)) return true;
    // Fenêtre écoulée → half-open pour la prochaine tentative
    if (!_disposed && !_halfOpen) {
      _halfOpen = true;
      _breakerOpenUntil = null;
      notifyListeners();
    }
    return false;
  }

  bool get canSync => _state == NetworkLinkState.online && !circuitOpen;

  /// Cooldown 30 s pour flush resume / périodique / transition réseau.
  bool allowScheduledFlush() {
    final last = _lastScheduledFlushAt;
    final t = _now();
    if (last != null && t.difference(last) < syncCooldown) {
      return false;
    }
    _lastScheduledFlushAt = t;
    return true;
  }

  void startProbing() {
    _probeTimer?.cancel();
    _probeTimer = Timer.periodic(probeInterval, (_) {
      unawaited(runProbe());
    });
    unawaited(runProbe());
  }

  void stopProbing() {
    _probeTimer?.cancel();
    _probeTimer = null;
  }

  Future<void> onAppResumed() async {
    startProbing();
    await runProbe();
  }

  void onAppPaused() {
    stopProbing();
  }

  Future<void> runProbe() async {
    if (_disposed || _probing) return;
    // Pendant open strict : pas de probe jusqu’à half-open
    final until = _breakerOpenUntil;
    if (until != null && _now().isBefore(until)) return;

    _probing = true;
    try {
      final ok = await _probe();
      if (_disposed) return;
      if (ok) {
        _onSuccessSignal();
      } else {
        _onFailSignal();
      }
    } catch (_) {
      if (_disposed) return;
      _onFailSignal();
    } finally {
      _probing = false;
    }
  }

  void reportSyncSuccess() {
    _consecutive5xx = 0;
    _onSuccessSignal();
  }

  void reportSyncFailure({required bool is5xx}) {
    if (is5xx) {
      _consecutive5xx++;
      if (_consecutive5xx >= fails5xxToOpen) {
        _openBreaker();
      }
    }
    _onFailSignal();
  }

  void _openBreaker() {
    _breakerOpenUntil = _now().add(breakerOpenDuration);
    _halfOpen = false;
    _consecutive5xx = 0;
    notifyListeners();
  }

  void _onSuccessSignal() {
    final t = _now();
    if (_halfOpen) {
      _halfOpen = false;
      _breakerOpenUntil = null;
      _consecutive5xx = 0;
    }
    _consecutiveFail = 0;
    _consecutiveOk++;
    _firstOkInSeries ??= t;

    final stable = t.difference(_firstOkInSeries!) >= stabilityWindow;
    if (_consecutiveOk >= oksToOnline && stable) {
      if (_state != NetworkLinkState.online) {
        _state = NetworkLinkState.online;
        notifyListeners();
        return;
      }
    }
    notifyListeners();
  }

  void _onFailSignal() {
    _consecutiveOk = 0;
    _firstOkInSeries = null;
    _consecutiveFail++;

    if (_halfOpen) {
      _openBreaker();
      return;
    }

    if (_consecutiveFail >= failsToDegraded) {
      if (_state == NetworkLinkState.online) {
        _state = NetworkLinkState.degraded;
      } else if (_state != NetworkLinkState.degraded) {
        _state = NetworkLinkState.offline;
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    stopProbing();
    super.dispose();
  }
}

final networkStatusProvider = ChangeNotifierProvider<NetworkStatus>((ref) {
  final client = ref.watch(apiClientProvider);
  return NetworkStatus(
    probe: () async {
      try {
        final res = await client.get<Map<String, dynamic>>(
          '/health',
          skipAuth: true,
        );
        final code = res.statusCode ?? 0;
        return code >= 200 && code < 300;
      } on DioException catch (e) {
        debugPrint('NetworkStatus probe: $e');
        return false;
      } catch (e) {
        debugPrint('NetworkStatus probe: $e');
        return false;
      }
    },
  );
});
