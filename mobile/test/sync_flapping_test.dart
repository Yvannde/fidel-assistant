import 'package:flutter_test/flutter_test.dart';

import 'package:fidel_assistant/services/network_status.dart';

/// QA Phase 6 #3 — flapping réseau : cooldown + hystérésis limitent les flush.
void main() {
  test('on/off every 2s for 60s → ≤2 scheduled flush passes', () async {
    var t = DateTime.utc(2026, 9, 11, 12);
    var onlineProbe = false;

    final net = NetworkStatus(
      probe: () async => onlineProbe,
      now: () => t,
      stabilityWindow: const Duration(seconds: 5),
      syncCooldown: const Duration(seconds: 30),
    );

    var flushPasses = 0;

    void tryScheduledFlush() {
      if (!net.canSync) return;
      if (!net.allowScheduledFlush()) return;
      flushPasses++;
    }

    // Simulate 60s with connectivity flipping every 2s, probe each tick,
    // and a scheduled-flush attempt each tick (like binder wakeups).
    for (var i = 0; i < 30; i++) {
      onlineProbe = i.isEven;
      await net.runProbe();
      tryScheduledFlush();
      t = t.add(const Duration(seconds: 2));
    }

    expect(flushPasses, lessThanOrEqualTo(2));
    expect(flushPasses, greaterThanOrEqualTo(0));
  });

  test('stable online allows flush then cooldown blocks second within 30s', () async {
    var t = DateTime.utc(2026, 9, 11, 12);
    final net = NetworkStatus(
      probe: () async => true,
      now: () => t,
      stabilityWindow: Duration.zero,
      syncCooldown: const Duration(seconds: 30),
    );
    await net.runProbe();
    await net.runProbe();
    expect(net.canSync, isTrue);

    expect(net.allowScheduledFlush(), isTrue);
    expect(net.allowScheduledFlush(), isFalse);

    t = t.add(const Duration(seconds: 31));
    expect(net.allowScheduledFlush(), isTrue);
  });
}
