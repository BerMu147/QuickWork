// Widget tests for the QuickWork admin console.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quickwork_admin/app/app.dart';
import 'package:quickwork_admin/core/api/api_client.dart';
import 'package:quickwork_admin/features/admin/providers/admin_provider.dart';
import 'package:quickwork_admin/features/auth/providers/auth_provider.dart';

void main() {
  setUpAll(() {
    // Prepare the HTTP client so provider construction doesn't crash.
    ApiClient.instance.init();
  });

  testWidgets('Unauthenticated admin console shows the login screen',
      (tester) async {
    final auth = AuthProvider();
    await tester.pumpWidget(
      QuickWorkAdminApp(
        authProvider: auth,
        adminProvider: AdminProvider(),
      ),
    );
    await tester.pumpAndSettle();

    // No admin navigation is shown; the login form is instead.
    expect(find.text('Administrator Console'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
  });
}

