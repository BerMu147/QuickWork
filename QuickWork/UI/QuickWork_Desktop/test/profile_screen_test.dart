// Widget tests for the Profile screen (login-gating + user info).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickwork_desktop/core/api/api_client.dart';
import 'package:quickwork_desktop/features/auth/data/auth_repository.dart';
import 'package:quickwork_desktop/features/auth/data/user_skill_repository.dart';
import 'package:quickwork_desktop/features/auth/models/login_response.dart';
import 'package:quickwork_desktop/features/auth/models/user_model.dart';
import 'package:quickwork_desktop/features/auth/models/user_skill_model.dart';
import 'package:quickwork_desktop/features/auth/providers/auth_provider.dart';
import 'package:quickwork_desktop/features/auth/providers/skill_provider.dart';
import 'package:quickwork_desktop/features/auth/screens/profile_screen.dart';
import 'package:quickwork_desktop/features/jobs/providers/job_posting_provider.dart';
import 'package:quickwork_desktop/features/lookup/providers/lookup_provider.dart';
import 'package:quickwork_desktop/features/reviews/data/review_repository.dart';
import 'package:quickwork_desktop/features/reviews/models/review_model.dart';
import 'package:quickwork_desktop/features/reviews/providers/review_provider.dart';

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

/// In-memory fake for the user-skills repository (no live backend).
class _FakeSkillRepository extends UserSkillRepository {
  _FakeSkillRepository({List<String> initial = const []})
      : _skills = initial
            .map((name) => UserSkillModel(
                  id: _nextId++,
                  userId: 999,
                  skillName: name,
                ))
            .toList();

  static int _nextId = 1;
  final List<UserSkillModel> _skills;

  @override
  Future<List<UserSkillModel>> fetchSkillsForUser(int userId) async =>
      List.of(_skills);

  @override
  Future<UserSkillModel> addSkill({
    required int userId,
    required String skillName,
  }) async {
    final skill = UserSkillModel(
      id: _nextId++,
      userId: userId,
      skillName: skillName,
    );
    _skills.add(skill);
    return skill;
  }

  @override
  Future<void> deleteSkill({required int id, required int userId}) async {
    _skills.removeWhere((s) => s.id == id);
  }
}

/// In-memory fake for the reviews repository (no live backend).
class _FakeReviewRepository extends ReviewRepository {
  _FakeReviewRepository({List<ReviewModel> initial = const []})
      : _reviews = List.of(initial);

  final List<ReviewModel> _reviews;

  @override
  Future<List<ReviewModel>> fetchReviewsForUser(int userId) async =>
      List.of(_reviews);

  @override
  Future<double> fetchAverageRating(int userId) async {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<int>(0, (acc, r) => acc + r.rating);
    return sum / _reviews.length;
  }
}

ReviewProvider _reviewProvider(List<ReviewModel> reviews) =>
    ReviewProvider(repository: _FakeReviewRepository(initial: reviews));

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
        ChangeNotifierProvider<SkillProvider>(create: (_) => SkillProvider()),
        ChangeNotifierProvider<ReviewProvider>(
          create: (_) => _reviewProvider(const []),
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
        ChangeNotifierProvider<SkillProvider>(create: (_) => SkillProvider()),
        ChangeNotifierProvider<ReviewProvider>(
          create: (_) => _reviewProvider(const []),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('@testuser'), findsOneWidget);
    // The completed-jobs, work-history and skills cards push the user-details
    // card (email/phone/city/gender) below the test viewport, so scroll the
    // profile ListView down to it before asserting. Pin the scrollable to the
    // outer list (the skills TextField contributes another Scrollable).
    await tester.scrollUntilVisible(
      find.text('test@example.com'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('061123456'), findsOneWidget);
    expect(find.text('Sarajevo'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    // The edit button is still below the viewport, so keep scrolling down to
    // it before asserting.
    await tester.scrollUntilVisible(
      find.text('Edit profile'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Edit profile'), findsOneWidget);
  });

  testWidgets('Profile lists and adds skills for the logged-in user',
      (tester) async {
    final auth = AuthProvider(repository: _FakeAuthRepository());
    await auth.login(username: 'testuser', password: 'pass');

    final skillRepo = _FakeSkillRepository(initial: const ['Plumbing']);
    final skillProvider = SkillProvider(repository: skillRepo);

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<LookupProvider>.value(value: LookupProvider()),
        ChangeNotifierProvider<JobPostingProvider>.value(
          value: JobPostingProvider(),
        ),
        ChangeNotifierProvider<SkillProvider>.value(value: skillProvider),
        ChangeNotifierProvider<ReviewProvider>(
          create: (_) => _reviewProvider(const []),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
    ));
    await tester.pumpAndSettle();

    // The new "Reviews & rating" card pushed the Skills card further down, so
    // scroll the profile ListView until the skills card (its existing chip)
    // is visible before interacting with it.
    await tester.scrollUntilVisible(
      find.text('Plumbing'),
      100,
      scrollable: find.byType(Scrollable).first,
    );

    // Existing skill is shown as a chip.
    expect(find.text('Plumbing'), findsOneWidget);

    // The profile ListView is the first scrollable; the skills TextField is
    // the only TextField in the tree.
    final fieldFinder = find.byType(TextField).first;
    await tester.enterText(fieldFinder, 'Carpentry');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // New skill now appears as a chip.
    expect(find.text('Carpentry'), findsOneWidget);
  });
}


