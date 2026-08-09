// Widget tests for the My Jobs screen (login-gating + tabs).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickwork_mobile/core/api/api_client.dart';
import 'package:quickwork_mobile/features/auth/data/auth_repository.dart';
import 'package:quickwork_mobile/features/auth/models/login_response.dart';
import 'package:quickwork_mobile/features/auth/models/user_model.dart';
import 'package:quickwork_mobile/features/auth/providers/auth_provider.dart';
import 'package:quickwork_mobile/features/jobs/providers/job_posting_provider.dart';
import 'package:quickwork_mobile/features/jobs/screens/my_jobs_screen.dart';

class _FakeAuthRepository extends AuthRepository {
  @override
  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    final user = UserModel(
      id: 999,
      firstName: 'Test',
      lastName: 'User',
      email: 'test@example.com',
      username: 'testuser',
      genderId: 1,
      genderName: 'Male',
      cityId: 1,
      cityName: 'Sarajevo',
      roles: const [],
    );
    return LoginResponse(token: 'fake.token.here', user: user);
  }
}

Future<AuthProvider> _authenticatedAuth() async {
  final auth = AuthProvider(repository: _FakeAuthRepository());
  await auth.login(username: 'testuser', password: 'pass');
  return auth;
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.instance.init();
  });

  testWidgets('My Jobs shows a login prompt to guests', (tester) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: AuthProvider()),
        ChangeNotifierProvider<JobPostingProvider>.value(
          value: JobPostingProvider(),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: MyJobsScreen())),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Log in to see your jobs and applications.'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });

  testWidgets('My Jobs shows Published and Applications tabs when logged in',
      (tester) async {
    final auth = await _authenticatedAuth();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<JobPostingProvider>.value(
          value: JobPostingProvider(),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: MyJobsScreen())),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Published'), findsOneWidget);
    expect(find.text('Applications'), findsOneWidget);
  });
}
