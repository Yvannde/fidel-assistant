import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fidel_assistant/main.dart';

void main() {
  testWidgets('Affiche le nom de l app', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FidelApp()));
    expect(find.text('Fidel Assistant'), findsOneWidget);
  });
}
