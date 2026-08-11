// Widget tests for the first-launch splash / intro screen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickwork_mobile/features/splash/screens/splash_screen.dart';

void main() {
  setUp(() {
    // First launch: no "seen" flag yet.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Splash shows the branded intro text on first launch',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const SplashScreen(),
      routes: {'/home': (context) => const Scaffold(body: Text('HOME'))},
    ));
    // Start the async init (prefs read + first-launch delay).
    await tester.pump();

    // Run the fade-in animation; still under the ~450ms navigation delay.
    await tester.pump(const Duration(milliseconds: 400));

    // Branded intro is visible before the hand-off.
    expect(find.text('QuickWork'), findsOneWidget);
    expect(find.text('HOME'), findsNothing);

    // Past the first-launch delay the splash hands off to the home screen.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text('HOME'), findsOneWidget);
  });
}
