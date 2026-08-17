// Widget tests for the registration screen.
//
// Note: widget tests block real network access, so the gender/city lookups
// will fail here. We only verify the screen renders its core fields.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:quickwork_desktop/core/api/api_client.dart';
import 'package:quickwork_desktop/features/auth/providers/auth_provider.dart';
import 'package:quickwork_desktop/features/auth/screens/registration_screen.dart';
import 'package:quickwork_desktop/features/lookup/providers/lookup_provider.dart';

Widget _wrap() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: AuthProvider()),
      ChangeNotifierProvider<LookupProvider>.value(value: LookupProvider()),
    ],
    child: const MaterialApp(home: RegistrationScreen()),
  );
}

void main() {
  setUpAll(() {
    ApiClient.instance.init();
  });

  testWidgets('Registration screen renders the core form fields', (tester) async {
    await tester.pumpWidget(_wrap());
    // Let the lookup load attempt settle (it will fail gracefully in tests).
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.text('Join QuickWork'), findsOneWidget);
    expect(find.text('First name'), findsOneWidget);
    expect(find.text('Last name'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Create account'), findsOneWidget);
  });
}

