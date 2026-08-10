import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickwork_mobile/app/app.dart';
import 'package:quickwork_mobile/core/api/api_client.dart';
import 'package:quickwork_mobile/features/auth/providers/auth_provider.dart';
import 'package:quickwork_mobile/features/jobs/providers/job_posting_provider.dart';
import 'package:quickwork_mobile/features/lookup/providers/lookup_provider.dart';

void main() {
  setUpAll(() {
    ApiClient.instance.init();
    // Mark the intro as seen so the smoke test lands on the home screen.
    SharedPreferences.setMockInitialValues({'has_seen_intro': true});
  });

  testWidgets('QuickWork app renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(QuickWorkApp(
      authProvider: AuthProvider(),
      lookupProvider: LookupProvider(),
      jobPostingProvider: JobPostingProvider(),
    ));

    // Let the splash hand off to the home screen settle.
    await tester.pumpAndSettle();

    // The home screen shows the app title.
    expect(find.text('QuickWork'), findsOneWidget);
  });
}


