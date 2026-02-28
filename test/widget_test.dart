import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sparkio/main.dart';
import 'package:sparkio/screens/home_screen.dart';

void main() {
  testWidgets('Sparkio app boots and mounts HomeScreen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed_v1': true});

    await tester.pumpWidget(const SparkioApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(SparkioApp), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
