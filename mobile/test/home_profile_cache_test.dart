import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fidel_assistant/features/home/data/home_profile_cache.dart';
import 'package:fidel_assistant/features/home/domain/dashboard_models.dart';

void main() {
  test('HomeProfileCache round-trip', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const profile = HomeProfile(
      nomComplet: 'Ivan Test',
      hasPatientProfile: true,
      isAidant: false,
      email: 'ivan@example.com',
    );
    await HomeProfileCache.save(prefs, profile);
    final read = HomeProfileCache.read(prefs);
    expect(read?.nomComplet, 'Ivan Test');
    expect(read?.hasPatientProfile, isTrue);
  });
}
