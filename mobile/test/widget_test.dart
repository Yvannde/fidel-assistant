import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fidel_assistant/main.dart';
import 'package:fidel_assistant/features/home/application/health_provider.dart';

void main() {
  testWidgets('Affiche le nom de l app et la zone config', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiHealthProvider.overrideWith((ref) async => 'ok — test'),
        ],
        child: const FidelApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fidel Assistant'), findsWidgets);
    expect(find.text('Configuration mobile'), findsOneWidget);
    expect(find.textContaining('Backend joignable'), findsOneWidget);
  });
}
