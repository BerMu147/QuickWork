// Widget tests for the home screen (auth-related behavior).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:quickwork_mobile/core/api/api_client.dart';
import 'package:quickwork_mobile/features/auth/providers/auth_provider.dart';
import 'package:quickwork_mobile/features/auth/providers/skill_provider.dart';
import 'package:quickwork_mobile/features/home/screens/home_screen.dart';
import 'package:quickwork_mobile/features/jobs/providers/job_posting_provider.dart';
import 'package:quickwork_mobile/features/reviews/providers/review_provider.dart';

Widget _wrap(AuthProvider auth) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<JobPostingProvider>.value(
        value: JobPostingProvider(),
      ),
      // ProfileScreen (reachable from the home tab) requires SkillProvider
      // and ReviewProvider.
      ChangeNotifierProvider<SkillProvider>(create: (_) => SkillProvider()),
      ChangeNotifierProvider<ReviewProvider>(create: (_) => ReviewProvider()),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

void main() {
  setUpAll(() {
    // Prepare the HTTP client so the jobs lookup attempt doesn't crash.
    ApiClient.instance.init();
  });

  testWidgets('Home shows a login icon when logged out', (tester) async {
    final auth = AuthProvider();
    await tester.pumpWidget(_wrap(auth));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.login), findsOneWidget);
    expect(find.text('QuickWork'), findsOneWidget);
    expect(find.byIcon(Icons.account_circle), findsNothing);
  });
}

