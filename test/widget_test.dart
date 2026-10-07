import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:antigravity_platformer/screens/splash_screen.dart';

void main() {
  testWidgets('app navigates from splash to main menu and level selection',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('ANTIGRITY'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Play'), findsOneWidget);
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(find.text('Select Level'), findsOneWidget);
  });
}
