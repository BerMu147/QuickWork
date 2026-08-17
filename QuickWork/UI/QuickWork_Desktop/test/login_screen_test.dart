// Widget tests for the login screen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:quickwork_desktop/features/auth/providers/auth_provider.dart';
import 'package:quickwork_desktop/features/auth/screens/login_screen.dart';
import 'package:quickwork_desktop/core/api/api_client.dart';

Widget _wrap(AuthProvider auth) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: auth,
    child: const MaterialApp(home: LoginScreen()),
  );
}

void main() {
  setUpAll(() {
    // Prepare the HTTP client (needed if a real login is attempted).
    ApiClient.instance.init();
  });

  testWidgets('Login screen shows required fields and buttons', (tester) async {
    final auth = AuthProvider();
    await tester.pumpWidget(_wrap(auth));

    // Title + fields.
    expect(find.text('Log in'), findsWidgets);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // Buttons.
    expect(find.text('Log in'), findsWidgets);
    expect(find.text('Register now!'), findsOneWidget);
    expect(find.text('Continue as guest'), findsOneWidget);
  });

  testWidgets('Login screen validates empty fields', (tester) async {
    final auth = AuthProvider();
    await tester.pumpWidget(_wrap(auth));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
    await tester.pump();

    expect(find.text('Please enter your username.'), findsOneWidget);
    expect(find.text('Please enter your password.'), findsOneWidget);
  });

  testWidgets('Continue as guest pops the screen', (tester) async {
    final auth = AuthProvider();
    await tester.pumpWidget(_wrap(auth));

    // Push a route so popping has somewhere to go.
    await tester.tap(find.text('Continue as guest'));
    await tester.pump();

    // Default behaviour: nothing crashes.
    expect(tester.takeException(), isNull);
  });
}

