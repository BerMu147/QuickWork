// Widget tests for the read-only applicant profile view (Bugfix 1) and the
// "view profile" affordance on the Review Applications screen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickwork_desktop/core/api/api_client.dart';
import 'package:quickwork_desktop/features/auth/data/user_repository.dart';
import 'package:quickwork_desktop/features/auth/data/user_skill_repository.dart';
import 'package:quickwork_desktop/features/auth/models/user_model.dart';
import 'package:quickwork_desktop/features/auth/models/user_skill_model.dart';
import 'package:quickwork_desktop/features/auth/providers/auth_provider.dart';
import 'package:quickwork_desktop/features/auth/screens/applicant_profile_screen.dart';
import 'package:quickwork_desktop/features/jobs/data/job_posting_repository.dart';
import 'package:quickwork_desktop/features/jobs/models/job_application_model.dart';
import 'package:quickwork_desktop/features/jobs/models/job_posting_model.dart';
import 'package:quickwork_desktop/features/jobs/providers/job_posting_provider.dart';
import 'package:quickwork_desktop/features/jobs/screens/review_applications_screen.dart';
import 'package:quickwork_desktop/features/reviews/data/review_repository.dart';
import 'package:quickwork_desktop/features/reviews/models/review_model.dart';
import 'package:quickwork_desktop/features/reviews/providers/review_provider.dart';

/// Fake for the user repository (returns a fixed applicant profile).
class _FakeUserRepository extends UserRepository {
  @override
  Future<UserModel> fetchUser(int id) async {
    return UserModel(
      id: id,
      firstName: 'Jane',
      lastName: 'Doe',
      email: 'jane@test.com',
      username: 'jane',
      genderId: 1,
      genderName: 'Female',
      cityId: 2,
      cityName: 'Mostar',
      bio: 'Experienced roofer.',
      roles: const [],
    );
  }
}

/// Fake for the user-skills repository (returns a fixed skill list).
class _FakeSkillRepository extends UserSkillRepository {
  @override
  Future<List<UserSkillModel>> fetchSkillsForUser(int userId) async {
    return const [
      UserSkillModel(id: 1, userId: 2, skillName: 'Roofing'),
      UserSkillModel(id: 2, userId: 2, skillName: 'Carpentry'),
    ];
  }
}

/// Fake for the reviews repository.
class _FakeReviewRepository extends ReviewRepository {
  _FakeReviewRepository({List<ReviewModel> reviews = const []})
      : _reviews = reviews;

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

/// Fake for the jobs repository: returns one completed published job and one
/// accepted application (i.e. completed jobs count = 2).
class _FakeJobRepository extends JobPostingRepository {
  @override
  Future<List<JobPostingModel>> fetchJobsForUser(int userId) async {
    return [
      JobPostingModel.fromJson({
        'id': 101,
        'title': 'Fix the roof',
        'description': 'desc',
        'categoryId': 1,
        'categoryName': 'Construction',
        'postedByUserId': userId,
        'postedByUserName': 'Jane Doe',
        'postedByUserEmail': 'jane@test.com',
        'cityId': 2,
        'cityName': 'Mostar',
        'paymentAmount': 100,
        'scheduledDate': '2024-01-01',
        'status': 'Completed',
        'isActive': true,
      }),
    ];
  }

  @override
  Future<List<JobApplicationModel>> fetchApplicationsForUser(int userId) async {
    return [
      JobApplicationModel.fromJson({
        'id': 201,
        'jobPostingId': 102,
        'jobPostingTitle': 'Paint the fence',
        'applicantUserId': userId,
        'applicantUserName': 'Jane Doe',
        'applicantUserEmail': 'jane@test.com',
        'status': 'Accepted',
      }),
    ];
  }
}

/// Fake for the applications-of-a-job repository used by ReviewApplicationsScreen.
class _FakeApplyRepo extends JobPostingRepository {
  _FakeApplyRepo(this._apps);
  final List<JobApplicationModel> _apps;

  @override
  Future<List<JobApplicationModel>> fetchApplicationsForJob(
      int jobPostingId) async {
    return _apps;
  }
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.instance.init();
  });

  final applicantName = 'Jane D.';
  final job = JobPostingModel.fromJson(const {
    'id': 1,
    'title': 'Fix the roof',
    'description': 'Need a roofer.',
    'categoryId': 1,
    'categoryName': 'Construction',
    'postedByUserId': 5,
    'postedByUserName': 'berinm',
    'postedByUserEmail': 'berinm@test.com',
    'cityId': 1,
    'cityName': 'Sarajevo',
    'paymentAmount': 100,
    'scheduledDate': '2024-01-01',
    'status': 'Open',
    'isActive': true,
  });

  testWidgets('Tapping an applicant name opens the applicant profile',
      (tester) async {
    final apps = [
      JobApplicationModel.fromJson({
        'id': 10,
        'jobPostingId': 1,
        'jobPostingTitle': 'Fix the roof',
        'applicantUserId': 2,
        'applicantUserName': applicantName,
        'applicantUserEmail': 'jane@test.com',
        'message': 'I can do this.',
        'status': 'Pending',
      }),
    ];
    final repo = _FakeApplyRepo(apps);
    final provider = JobPostingProvider(repository: repo);
    final reviewProvider = ReviewProvider(
      repository: _FakeReviewRepository(),
    );

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: AuthProvider()),
        ChangeNotifierProvider<JobPostingProvider>.value(value: provider),
        ChangeNotifierProvider<ReviewProvider>.value(value: reviewProvider),
      ],
      child: MaterialApp(home: ReviewApplicationsScreen(job: job)),
    ));
    await tester.pumpAndSettle();

    // Tap the applicant's name (within the tappable tile).
    await tester.tap(find.text(applicantName));
    await tester.pumpAndSettle();

    // The applicant profile screen is now shown (app bar title = applicant).
    expect(find.byType(ApplicantProfileScreen), findsOneWidget);
    expect(find.text(applicantName), findsWidgets);
  });

  testWidgets('Applicant profile shows the applicant data, not the viewer\'s',
      (tester) async {
    final reviews = [
      ReviewModel(
        id: 1,
        jobPostingId: 1,
        jobPostingTitle: 'Fix the roof',
        reviewerUserId: 3,
        reviewerUserName: 'Bob K.',
        reviewedUserId: 2,
        reviewedUserName: applicantName,
        rating: 4,
        comment: 'Great work.',
      ),
    ];
    final reviewRepo = _FakeReviewRepository(reviews: reviews);

    await tester.pumpWidget(MaterialApp(
      home: ApplicantProfileScreen(
        userId: 2,
        userName: applicantName,
        userRepository: _FakeUserRepository(),
        skillRepository: _FakeSkillRepository(),
        reviewRepository: reviewRepo,
        jobRepository: _FakeJobRepository(),
      ),
    ));
    await tester.pumpAndSettle();

    // Header shows the applicant's own name + username + bio.
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('@jane'), findsOneWidget);
    expect(find.text('Experienced roofer.'), findsOneWidget);

    // Completed jobs = 1 completed published job + 1 accepted application.
    expect(find.text('2'), findsWidgets);

    // Reviewer of the applicant, not the viewer.
    expect(find.text('Bob K.'), findsOneWidget);
    expect(find.text('Great work.'), findsOneWidget);

    // Scroll to the Skills card and check the applicant's skills are shown.
    await tester.scrollUntilVisible(
      find.text('Roofing'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Roofing'), findsOneWidget);
    expect(find.text('Carpentry'), findsOneWidget);

    // Scroll to the user-details card (City) and check the applicant's city.
    await tester.scrollUntilVisible(
      find.text('Mostar'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Mostar'), findsOneWidget);
  });
}
