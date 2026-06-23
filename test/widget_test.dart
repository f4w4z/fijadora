import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phoebe_homes/main.dart';

void main() {
  testWidgets('App renders login screen initially', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Let the route navigation complete
    await tester.pumpAndSettle();

    // Verify that the title 'Phoebe Homes' and sign-in widgets are rendered
    expect(find.text('Phoebe Homes'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text("Don't have an account? "), findsOneWidget);
  });
}
