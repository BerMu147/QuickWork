// Widget tests for the Profile screen (login-gating + user info).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickwork_mobile/core/api/api_client.dart';
import 'package:quickwork_mobile/features/auth/data/auth_repository.dart';
import 'package:quickwork_mobile/features/auth/models/login_response.dart';
import 'package:quickwork_mobile/features/auth/models/user_model.dart';
import 'package:quickwork_mobile/features/auth/providers/auth_provider.dart';
import 'package:quickwork_mobile/features/auth/screens/profile_screen.dart';
import 'package:quickwork_mobile/features/jobs/providers/job_posting_provider.dart';
import 'package:quickwork_mobile/features/lookup/providers/lookup_provider.dart';

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
      phoneNumber: '061123456',
      roles: const [],
    );
    return LoginResponse(token: 'fake.token.here', user: user);
  }
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.instance.init();
  });

  testWidgets('Profile shows a login prompt to guests', (tester) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: AuthProvider()),
        ChangeNotifierProvider<LookupProvider>.value(value: LookupProvider()),
        ChangeNotifierProvider<JobPostingProvider>.value(
          value: JobPostingProvider(),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Log in to see your profile.'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });

  testWidgets('Profile shows the logged-in user info', (tester) async {
    final auth = AuthProvider(repository: _FakeAuthRepository());
    await auth.login(username: 'testuser', password: 'pass');

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<LookupProvider>.value(value: LookupProvider()),
        ChangeNotifierProvider<JobPostingProvider>.value(
          value: JobPostingProvider(),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('@testuser'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('061123456'), findsOneWidget);
    expect(find.text('Sarajevo'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    // The added "Completed jobs" stat card pushes the edit button below the
    // test viewport, so scroll down to it before asserting.
    await tester.scrollUntilVisible(find.text('Edit profile'), 100);
    expect(find.text('Edit profile'), findsOneWidget);
  });
}


