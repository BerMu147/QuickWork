// Widget tests for the home screen (auth-related behavior).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:quickwork_mobile/features/auth/providers/auth_provider.dart';
import 'package:quickwork_mobile/features/home/screens/home_screen.dart';

Widget _wrap(AuthProvider auth) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: auth,
    child: const MaterialApp(home: HomeScreen()),
  );
}

void main() {
  testWidgets('Home shows a login icon when logged out', (tester) async {
    final auth = AuthProvider();
    await tester.pumpWidget(_wrap(auth));

    expect(find.byIcon(Icons.login), findsOneWidget);
    expect(find.text('QuickWork'), findsOneWidget);
    expect(find.byIcon(Icons.account_circle), findsNothing);
  });
}

