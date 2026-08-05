// Basic smoke test for the QuickWork app.
import 'package:flutter_test/flutter_test.dart';

import 'package:quickwork_mobile/app/app.dart';
import 'package:quickwork_mobile/features/auth/providers/auth_provider.dart';

void main() {
  testWidgets('QuickWork app renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(QuickWorkApp(authProvider: AuthProvider()));

    // The placeholder home shows the app title.
    expect(find.text('QuickWork'), findsOneWidget);
  });
}

