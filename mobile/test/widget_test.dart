import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fidel_assistant/core/locale/locale_controller.dart';
import 'package:fidel_assistant/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Language screen is the entry when no locale saved', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const FidelApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('langue'), findsWidgets);
  });
}
