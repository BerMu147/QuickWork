// Regression test for Bugfix 2: per-user provider state (e.g. skills, my-jobs,
// reviews, messages) must be cleared on logout so one account's data never
// bleeds into another account's session.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickwork_mobile/core/api/api_client.dart';
import 'package:quickwork_mobile/features/auth/data/auth_repository.dart';
import 'package:quickwork_mobile/features/auth/data/user_skill_repository.dart';
import 'package:quickwork_mobile/features/auth/models/login_response.dart';
import 'package:quickwork_mobile/features/auth/models/user_model.dart';
import 'package:quickwork_mobile/features/auth/models/user_skill_model.dart';
import 'package:quickwork_mobile/features/auth/providers/auth_provider.dart';
import 'package:quickwork_mobile/features/auth/providers/skill_provider.dart';
import 'package:quickwork_mobile/features/home/screens/home_screen.dart';
import 'package:quickwork_mobile/features/jobs/providers/job_posting_provider.dart';
import 'package:quickwork_mobile/features/jobs/providers/message_provider.dart';
import 'package:quickwork_mobile/features/reviews/data/review_repository.dart';
import 'package:quickwork_mobile/features/reviews/models/review_model.dart';
import 'package:quickwork_mobile/features/reviews/providers/review_provider.dart';

/// Fake auth repo that always logs us in as user A (id 999, username 'usera').
class _FakeAuthRepository extends AuthRepository {
  @override
  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    return LoginResponse(
      token: 'fake.token',
      user: UserModel(
        id: 999,
        firstName: 'User',
        lastName: 'A',
        email: 'usera@test.com',
        username: 'usera',
        genderId: 1,
        genderName: 'Male',
        cityId: 1,
        cityName: 'Sarajevo',
        roles: const [],
      ),
    );
  }
}

/// Fake skill repo that returns a cached skill immediately.
class _FakeSkillRepository extends UserSkillRepository {
  _FakeSkillRepository({List<String> skills = const []})
      : _skills = skills
            .map((name) => UserSkillModel(id: _nextId++, userId: 999, skillName: name))
            .toList();

  static int _nextId = 1;
  final List<UserSkillModel> _skills;

  @override
  Future<List<UserSkillModel>> fetchSkillsForUser(int userId) async =>
      List.of(_skills);
}

Widget _wrap({
  required AuthProvider auth,
  required SkillProvider skillProvider,
  required JobPostingProvider jobProvider,
  required ReviewProvider reviewProvider,
  required MessageProvider messageProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<SkillProvider>.value(value: skillProvider),
      ChangeNotifierProvider<JobPostingProvider>.value(value: jobProvider),
      ChangeNotifierProvider<ReviewProvider>.value(value: reviewProvider),
      ChangeNotifierProvider<MessageProvider>.value(value: messageProvider),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.instance.init();
  });

  testWidgets('Logout clears the shared per-user provider state',
      (tester) async {
    // Log in as user A.
    final auth = AuthProvider(repository: _FakeAuthRepository());
    await auth.login(username: 'usera', password: 'pass');

    // Seed user A's skills via the provider.
    final skillProvider = SkillProvider(
      repository: _FakeSkillRepository(skills: const ['Roofing', 'Carpentry']),
    );
    await skillProvider.loadSkills(999);
    expect(skillProvider.skills, hasLength(2));

    final jobProvider = JobPostingProvider();
    final reviewProvider = ReviewProvider(
      repository: _FakeEmptyReviewRepository(),
    );
    final messageProvider = MessageProvider();

    await tester.pumpWidget(_wrap(
      auth: auth,
      skillProvider: skillProvider,
      jobProvider: jobProvider,
      reviewProvider: reviewProvider,
      messageProvider: messageProvider,
    ));
    await tester.pumpAndSettle();

    // Skills are present before logout.
    expect(skillProvider.skills, hasLength(2));

    // Trigger logout via the account popup menu.
    await tester.tap(find.byIcon(Icons.account_circle));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    // After logout the per-user provider state is cleared, so a subsequent
    // account cannot see user A's skills.
    expect(auth.isAuthenticated, isFalse);
    expect(skillProvider.skills, isEmpty);
    expect(skillProvider.skills.any((s) => s.skillName == 'Roofing'), isFalse);
  });
}

/// Empty reviews repo so ReviewProvider can be constructed without a backend.
class _FakeEmptyReviewRepository extends ReviewRepository {
  @override
  Future<List<ReviewModel>> fetchReviewsForUser(int userId) async => [];

  @override
  Future<double> fetchAverageRating(int userId) async => 0;
}
