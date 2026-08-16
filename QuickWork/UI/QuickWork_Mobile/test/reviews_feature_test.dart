// Widget tests for the reviews feature: profile rating display, the
// "Leave a review" action on completed jobs, and the review form itself.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickwork_mobile/core/api/api_client.dart';
import 'package:quickwork_mobile/features/auth/data/auth_repository.dart';
import 'package:quickwork_mobile/features/auth/models/login_response.dart';
import 'package:quickwork_mobile/features/auth/models/user_model.dart';
import 'package:quickwork_mobile/features/auth/providers/auth_provider.dart';
import 'package:quickwork_mobile/features/auth/providers/skill_provider.dart';
import 'package:quickwork_mobile/features/auth/screens/profile_screen.dart';
import 'package:quickwork_mobile/features/jobs/data/job_posting_repository.dart';
import 'package:quickwork_mobile/features/jobs/models/job_application_model.dart';
import 'package:quickwork_mobile/features/jobs/models/job_posting_model.dart';
import 'package:quickwork_mobile/features/jobs/providers/job_posting_provider.dart';
import 'package:quickwork_mobile/features/jobs/screens/review_applications_screen.dart';
import 'package:quickwork_mobile/features/lookup/providers/lookup_provider.dart';
import 'package:quickwork_mobile/features/reviews/data/review_repository.dart';
import 'package:quickwork_mobile/features/reviews/models/review_model.dart';
import 'package:quickwork_mobile/features/reviews/providers/review_provider.dart';
import 'package:quickwork_mobile/features/reviews/screens/review_form_screen.dart';

/// A logged-in user used across the tests.
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

/// In-memory fake for the reviews repository.
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

  @override
  Future<ReviewModel> createReview({
    required int reviewerUserId,
    required int reviewedUserId,
    required int jobPostingId,
    required int rating,
    String? comment,
  }) async {
    final review = ReviewModel(
      id: _reviews.length + 1,
      jobPostingId: jobPostingId,
      jobPostingTitle: 'Fix the roof',
      reviewerUserId: reviewerUserId,
      reviewerUserName: 'Test User',
      reviewedUserId: reviewedUserId,
      reviewedUserName: 'Jane D.',
      rating: rating,
      comment: comment,
    );
    _reviews.add(review);
    return review;
  }
}

/// Fake for the jobs repository so we can drive the completed-job lifecycle.
class _FakeJobRepo extends JobPostingRepository {
  _FakeJobRepo({required List<JobApplicationModel> apps, required String status})
      : _apps = apps,
        _status = status;

  final List<JobApplicationModel> _apps;
  String _status;

  @override
  Future<List<JobApplicationModel>> fetchApplicationsForJob(
      int jobPostingId) async {
    return _apps;
  }

  @override
  Future<JobPostingModel> updateJobStatus({
    required int jobPostingId,
    required String status,
    required int postedByUserId,
  }) async {
    _status = status;
    return JobPostingModel.fromJson({
      'id': _job.id,
      'title': _job.title,
      'description': _job.description,
      'cityId': _job.cityId,
      'cityName': _job.cityName,
      'categoryId': _job.categoryId,
      'categoryName': _job.categoryName,
      'paymentAmount': _job.paymentAmount,
      'status': status,
      'postedByUserId': _job.postedByUserId,
      'postedByUserName': _job.postedByUserName,
    });
  }

  String get status => _status;
}

final _job = JobPostingModel.fromJson(const {
  'id': 1,
  'title': 'Fix the roof',
  'description': 'Need a roofer.',
  'cityId': 1,
  'cityName': 'Sarajevo',
  'categoryId': 1,
  'categoryName': 'Construction',
  'paymentAmount': 100,
  'status': 'Completed',
  'postedByUserId': 5,
  'postedByUserName': 'berinm',
});

final _acceptedApp = JobApplicationModel.fromJson(const {
  'id': 10,
  'jobPostingId': 1,
  'jobPostingTitle': 'Fix the roof',
  'applicantUserId': 2,
  'applicantUserName': 'Jane D.',
  'applicantUserEmail': 'jane@test.com',
  'status': 'Accepted',
});

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.instance.init();
  });

  testWidgets('Profile shows the average rating and received reviews',
      (tester) async {
    final auth = AuthProvider(repository: _FakeAuthRepository());
    await auth.login(username: 'testuser', password: 'pass');

    final reviews = [
      ReviewModel(
        id: 1,
        jobPostingId: 1,
        jobPostingTitle: 'Fix the roof',
        reviewerUserId: 2,
        reviewerUserName: 'Jane D.',
        reviewedUserId: 999,
        reviewedUserName: 'Test User',
        rating: 5,
        comment: 'Great worker!',
      ),
      ReviewModel(
        id: 2,
        jobPostingId: 2,
        jobPostingTitle: 'Paint the fence',
        reviewerUserId: 3,
        reviewerUserName: 'Bob K.',
        reviewedUserId: 999,
        reviewedUserName: 'Test User',
        rating: 3,
      ),
    ];
    final reviewProvider = ReviewProvider(
      repository: _FakeReviewRepository(initial: reviews),
    );

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<LookupProvider>.value(value: LookupProvider()),
        ChangeNotifierProvider<JobPostingProvider>.value(
          value: JobPostingProvider(),
        ),
        ChangeNotifierProvider<SkillProvider>(create: (_) => SkillProvider()),
        ChangeNotifierProvider<ReviewProvider>.value(value: reviewProvider),
      ],
      child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
    ));
    await tester.pumpAndSettle();

    // Scroll to the Reviews & rating card.
    await tester.scrollUntilVisible(
      find.text('Reviews & rating'),
      100,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Reviews & rating'), findsOneWidget);
    // Average (5+3)/2 = 4.0.
    expect(find.text('4.0'), findsOneWidget);
    expect(find.text('2 reviews'), findsOneWidget);
    // Both reviewers are listed.
    expect(find.text('Jane D.'), findsOneWidget);
    expect(find.text('Bob K.'), findsOneWidget);
    expect(find.text('Great worker!'), findsOneWidget);
  });

  testWidgets('Completed job lets the publisher review an accepted worker',
      (tester) async {
    final auth = AuthProvider(repository: _FakeAuthRepository());
    await auth.login(username: 'testuser', password: 'pass');

    final jobRepo = _FakeJobRepo(
      apps: [_acceptedApp],
      status: 'Completed',
    );
    final jobsProvider = JobPostingProvider(repository: jobRepo);
    final reviewProvider = ReviewProvider(
      repository: _FakeReviewRepository(),
    );

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<JobPostingProvider>.value(value: jobsProvider),
        ChangeNotifierProvider<ReviewProvider>.value(value: reviewProvider),
      ],
      child: MaterialApp(home: ReviewApplicationsScreen(job: _job)),
    ));
    await tester.pumpAndSettle();

    // Completed job + accepted worker => a Review button is shown.
    expect(find.text('Review'), findsOneWidget);

    // Open the review sheet, select 5 stars and submit.
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();

    expect(find.text('Leave a review'), findsOneWidget);
    expect(find.text('Reviewing: Jane D.'), findsOneWidget);

    await tester.tap(find.text('Submit review'));
    await tester.pumpAndSettle();

    // The reviewed marker appears once a review has been submitted successfully.
    expect(find.text('Reviewed'), findsOneWidget);
  });

  testWidgets('Open jobs do not show a Review button for workers',
      (tester) async {
    final pendingApp = JobApplicationModel.fromJson(const {
      'id': 10,
      'jobPostingId': 1,
      'jobPostingTitle': 'Fix the roof',
      'applicantUserId': 2,
      'applicantUserName': 'Jane D.',
      'applicantUserEmail': 'jane@test.com',
      'status': 'Pending',
    });
    final openJob = JobPostingModel.fromJson(const {
      'id': 1,
      'title': 'Fix the roof',
      'description': 'Need a roofer.',
      'cityId': 1,
      'cityName': 'Sarajevo',
      'categoryId': 1,
      'categoryName': 'Construction',
      'paymentAmount': 100,
      'status': 'Open',
      'postedByUserId': 5,
      'postedByUserName': 'berinm',
    });
    final jobRepo = _FakeJobRepo(apps: [pendingApp], status: 'Open');
    final jobsProvider = JobPostingProvider(repository: jobRepo);
    final reviewProvider = ReviewProvider(
      repository: _FakeReviewRepository(),
    );

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: AuthProvider()),
        ChangeNotifierProvider<JobPostingProvider>.value(value: jobsProvider),
        ChangeNotifierProvider<ReviewProvider>.value(value: reviewProvider),
      ],
      child: MaterialApp(home: ReviewApplicationsScreen(job: openJob)),
    ));
    await tester.pumpAndSettle();

    // The worker is pending and the job is open, so no Review button.
    expect(find.text('Review'), findsNothing);
  });

  testWidgets('Review form validates the rating and submits a comment',
      (tester) async {
    int? submittedRating;
    String? submittedComment;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ReviewFormScreen(
          reviewerName: 'Test User',
          reviewedName: 'Jane D.',
          jobTitle: 'Fix the roof',
          onSubmit: (rating, comment) async {
            submittedRating = rating;
            submittedComment = comment;
          },
        ),
      ),
    ));

    expect(find.text('Leave a review'), findsOneWidget);

    // A star picker offers five star icons.
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));

    // Enter a comment and submit.
    await tester.enterText(
      find.byType(TextField),
      'Very professional.',
    );
    await tester.tap(find.text('Submit review'));
    await tester.pumpAndSettle();

    expect(submittedRating, 5);
    expect(submittedComment, 'Very professional.');
  });
}
