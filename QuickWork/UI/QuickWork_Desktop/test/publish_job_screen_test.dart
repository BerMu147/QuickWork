// Widget tests for the Publish Job screen (form fields render).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:quickwork_desktop/core/api/api_client.dart';
import 'package:quickwork_desktop/features/auth/providers/auth_provider.dart';
import 'package:quickwork_desktop/features/jobs/providers/job_posting_provider.dart';
import 'package:quickwork_desktop/features/jobs/screens/publish_job_screen.dart';
import 'package:quickwork_desktop/features/lookup/providers/lookup_provider.dart';

void main() {
  setUpAll(() {
    ApiClient.instance.init();
  });

  testWidgets('Publish Job screen renders the core form fields',
      (tester) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: AuthProvider()),
        ChangeNotifierProvider<JobPostingProvider>.value(
          value: JobPostingProvider(),
        ),
        ChangeNotifierProvider<LookupProvider>.value(
          value: LookupProvider(),
        ),
      ],
      child: const MaterialApp(home: PublishJobScreen()),
    ));
    await tester.pumpAndSettle();

    // Core form controls are present.
    expect(find.text('Publish a job'), findsOneWidget);
    expect(find.text('Job title'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('City'), findsOneWidget);
    expect(find.text('Payment (KM)'), findsOneWidget);
    expect(find.text('Publish job'), findsOneWidget);
  });
}
