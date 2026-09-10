import 'package:flutter_test/flutter_test.dart';

import 'package:fidel_assistant/services/network_status.dart';

void main() {
  test('2 probes OK + stability window → online', () async {
    var t = DateTime.utc(2026, 9, 10, 12);
    final net = NetworkStatus(
      probe: () async => true,
      now: () => t,
      stabilityWindow: const Duration(seconds: 5),
    );

    await net.runProbe();
    expect(net.state, NetworkLinkState.offline);

    t = t.add(const Duration(seconds: 6));
    await net.runProbe();
    expect(net.state, NetworkLinkState.online);
    expect(net.canSync, isTrue);
  });

  test('flapping: second OK before stability stays offline', () async {
    var t = DateTime.utc(2026, 9, 10, 12);
    final net = NetworkStatus(
      probe: () async => true,
      now: () => t,
      stabilityWindow: const Duration(seconds: 5),
    );

    await net.runProbe();
    t = t.add(const Duration(seconds: 2));
    await net.runProbe();
    expect(net.state, NetworkLinkState.offline);
  });

  test('3 fails from online → degraded', () async {
    var t = DateTime.utc(2026, 9, 10, 12);
    var ok = true;
    final net = NetworkStatus(
      probe: () async => ok,
      now: () => t,
      stabilityWindow: Duration.zero,
    );
    await net.runProbe();
    await net.runProbe();
    expect(net.state, NetworkLinkState.online);

    ok = false;
    await net.runProbe();
    await net.runProbe();
    await net.runProbe();
    expect(net.state, NetworkLinkState.degraded);
    expect(net.canSync, isFalse);
  });

  test('5× 5xx opens breaker for 2 min then half-open', () async {
    var t = DateTime.utc(2026, 9, 10, 12);
    final net = NetworkStatus(
      probe: () async => true,
      now: () => t,
      stabilityWindow: Duration.zero,
      breakerOpenDuration: const Duration(minutes: 2),
    );
    await net.runProbe();
    await net.runProbe();
    expect(net.canSync, isTrue);

    for (var i = 0; i < 5; i++) {
      net.reportSyncFailure(is5xx: true);
    }
    expect(net.circuitOpen, isTrue);
    expect(net.canSync, isFalse);

    t = t.add(const Duration(minutes: 2, seconds: 1));
    expect(net.circuitOpen, isFalse);
    expect(net.isHalfOpen, isTrue);

    await net.runProbe();
    expect(net.isHalfOpen, isFalse);
    expect(net.circuitOpen, isFalse);
  });

  test('allowScheduledFlush enforces 30s cooldown', () {
    var t = DateTime.utc(2026, 9, 10, 12);
    final net = NetworkStatus(
      probe: () async => true,
      now: () => t,
      syncCooldown: const Duration(seconds: 30),
    );
    expect(net.allowScheduledFlush(), isTrue);
    expect(net.allowScheduledFlush(), isFalse);
    t = t.add(const Duration(seconds: 31));
    expect(net.allowScheduledFlush(), isTrue);
  });
}
