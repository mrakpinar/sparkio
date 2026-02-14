import 'package:flutter_test/flutter_test.dart';

import 'package:sparkio/main.dart';
import 'package:sparkio/screens/home_screen.dart';

void main() {
  testWidgets('Sparkio app boots and mounts HomeScreen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SparkioApp());

    expect(find.byType(SparkioApp), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
