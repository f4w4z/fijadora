import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fijadora_core/app_config.dart';
import 'package:fijadora_core/app_entry.dart';

void main() {
  testWidgets('App renders login screen initially', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.customer),
        ],
        child: const FijadoraApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Fijadora'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text("Don't have an account? "), findsOneWidget);
  });
}
