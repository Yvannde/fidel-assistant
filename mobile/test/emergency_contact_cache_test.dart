import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fidel_assistant/services/emergency_contact_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('EmergencyContactCache saves and clears first contact', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cache = EmergencyContactCache(prefs);

    expect(cache.phone, isNull);

    await cache.saveFirst(phone: '+237690000099', name: 'Marie');
    expect(cache.phone, '+237690000099');
    expect(cache.name, 'Marie');

    await cache.clear();
    expect(cache.phone, isNull);
  });
}
