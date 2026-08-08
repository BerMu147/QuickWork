import 'package:flutter_test/flutter_test.dart';

import 'package:quickwork_mobile/app/app.dart';
import 'package:quickwork_mobile/core/api/api_client.dart';
import 'package:quickwork_mobile/features/auth/providers/auth_provider.dart';
import 'package:quickwork_mobile/features/jobs/providers/job_posting_provider.dart';
import 'package:quickwork_mobile/features/lookup/providers/lookup_provider.dart';

void main() {
  setUpAll(() {
    ApiClient.instance.init();
  });

  testWidgets('QuickWork app renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(QuickWorkApp(
      authProvider: AuthProvider(),
      lookupProvider: LookupProvider(),
      jobPostingProvider: JobPostingProvider(),
    ));

    // Let the jobs list load attempt settle so no timers are left pending.
    await tester.pumpAndSettle();

    // The home screen shows the app title.
    expect(find.text('QuickWork'), findsOneWidget);
  });
}

