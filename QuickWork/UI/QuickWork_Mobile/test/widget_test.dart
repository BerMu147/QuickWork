// Basic smoke test for the QuickWork app.
import 'package:flutter_test/flutter_test.dart';

import 'package:quickwork_mobile/app/app.dart';
import 'package:quickwork_mobile/features/auth/providers/auth_provider.dart';
import 'package:quickwork_mobile/features/lookup/providers/lookup_provider.dart';

void main() {
  testWidgets('QuickWork app renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(QuickWorkApp(
      authProvider: AuthProvider(),
      lookupProvider: LookupProvider(),
    ));

    // The home screen shows the app title.
    expect(find.text('QuickWork'), findsOneWidget);
  });
}

