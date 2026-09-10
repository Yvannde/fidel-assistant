import 'dart:io' show HttpDate;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fidel_assistant/services/server_clock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('observeHttpDate sets offset and corrects now()', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final device = DateTime.utc(2026, 9, 10, 12);
    final clock = ServerClock(prefs, now: () => device);

    final server = DateTime.utc(2026, 9, 10, 15);
    clock.observeHttpDate(HttpDate.format(server));

    expect(clock.offset, const Duration(hours: 3));
    expect(clock.now(), server);
    expect(prefs.getInt(ServerClock.offsetKey), isNotNull);
  });

  test('invalid Date is ignored', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final device = DateTime.utc(2026, 9, 10, 12);
    final clock = ServerClock(prefs, now: () => device);

    clock.observeHttpDate('not-a-date');
    expect(clock.offset, isNull);
    expect(clock.now(), device);
  });

  test('load restores persisted offset', () async {
    SharedPreferences.setMockInitialValues({
      ServerClock.offsetKey: const Duration(hours: -2).inMilliseconds,
    });
    final prefs = await SharedPreferences.getInstance();
    final device = DateTime.utc(2026, 9, 10, 12);
    final clock = ServerClock(prefs, now: () => device)..load();
    expect(clock.now(), DateTime.utc(2026, 9, 10, 10));
  });
}
