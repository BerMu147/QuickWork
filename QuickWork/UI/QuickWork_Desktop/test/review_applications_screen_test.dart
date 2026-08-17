// Widget tests for the publisher's review-applications screen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickwork_desktop/core/api/api_client.dart';
import 'package:quickwork_desktop/features/auth/providers/auth_provider.dart';
import 'package:quickwork_desktop/features/jobs/data/job_posting_repository.dart';
import 'package:quickwork_desktop/features/jobs/models/job_application_model.dart';
import 'package:quickwork_desktop/features/jobs/models/job_posting_model.dart';
import 'package:quickwork_desktop/features/jobs/providers/job_posting_provider.dart';
import 'package:quickwork_desktop/features/jobs/screens/review_applications_screen.dart';
import 'package:quickwork_desktop/features/reviews/data/review_repository.dart';
import 'package:quickwork_desktop/features/reviews/models/review_model.dart';
import 'package:quickwork_desktop/features/reviews/providers/review_provider.dart';

class _FakeRepo extends JobPostingRepository {
  _FakeRepo(this._apps);

  final List<JobApplicationModel> _apps;
  final List<String> _setStatuses = [];

  List<String> get setStatuses => _setStatuses;

  @override
  Future<List<JobApplicationModel>> fetchApplicationsForJob(
      int jobPostingId) async {
    return _apps;
  }

  @override
  Future<JobApplicationModel> updateApplicationStatus({
    required int applicationId,
    required int jobPostingId,
    required String status,
    String? message,
  }) async {
    _setStatuses.add(status);
    final idx = _apps.indexWhere((a) => a.id == applicationId);
    return JobApplicationModel(
      id: applicationId,
      jobPostingId: jobPostingId,
      jobPostingTitle: _apps[idx].jobPostingTitle,
      applicantUserId: _apps[idx].applicantUserId,
      applicantUserName: _apps[idx].applicantUserName,
      applicantUserEmail: _apps[idx].applicantUserEmail,
      message: _apps[idx].message,
      status: status,
      appliedAt: _apps[idx].appliedAt,
      isActive: true,
    );
  }

  final List<String> _statuses = [];
  List<String> get statuses => _statuses;

  @override
  Future<JobPostingModel> updateJobStatus({
    required int jobPostingId,
    required String status,
    required int postedByUserId,
  }) async {
    _statuses.add(status);
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
}

/// In-memory fake for the reviews repository (no live backend).
class _FakeReviewRepository extends ReviewRepository {
  final List<ReviewModel> _reviews = [];

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
      jobPostingTitle: _job.title,
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

final ReviewProvider _reviewProvider = ReviewProvider(
  repository: _FakeReviewRepository(),
);

final _job = JobPostingModel.fromJson(const {
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

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.instance.init();
  });

  testWidgets('Review screen lists applications with Accept/Reject',
      (tester) async {
    final apps = [
      JobApplicationModel.fromJson(const {
        'id': 10,
        'jobPostingId': 1,
        'jobPostingTitle': 'Fix the roof',
        'applicantUserId': 2,
        'applicantUserName': 'Jane D.',
        'applicantUserEmail': 'jane@test.com',
        'message': 'I can do this.',
        'status': 'Pending',
      }),
    ];
    final repo = _FakeRepo(apps);
    final provider = JobPostingProvider(repository: repo);

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: AuthProvider()),
        ChangeNotifierProvider<JobPostingProvider>.value(value: provider),
        ChangeNotifierProvider<ReviewProvider>.value(value: _reviewProvider),
      ],
      child: MaterialApp(home: ReviewApplicationsScreen(job: _job)),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Jane D.'), findsOneWidget);
    expect(find.text('jane@test.com'), findsOneWidget);
    expect(find.text('I can do this.'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);

    // Accept the application.
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(repo.setStatuses, contains('Accepted'));
  });

  testWidgets('Publisher can advance the job status to complete',
      (tester) async {
    final apps = [
      JobApplicationModel.fromJson(const {
        'id': 10,
        'jobPostingId': 1,
        'jobPostingTitle': 'Fix the roof',
        'applicantUserId': 2,
        'applicantUserName': 'Jane D.',
        'applicantUserEmail': 'jane@test.com',
        'message': 'I can do this.',
        'status': 'Pending',
      }),
    ];
    final repo = _FakeRepo(apps);
    final provider = JobPostingProvider(repository: repo);

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: AuthProvider()),
        ChangeNotifierProvider<JobPostingProvider>.value(value: provider),
        ChangeNotifierProvider<ReviewProvider>.value(value: _reviewProvider),
      ],
      child: MaterialApp(home: ReviewApplicationsScreen(job: _job)),
    ));
    await tester.pumpAndSettle();

    // Open job -> shows "Mark In Progress".
    expect(find.text('Mark In Progress'), findsOneWidget);

    await tester.tap(find.text('Mark In Progress'));
    await tester.pumpAndSettle();

    // Now InProgress -> shows "Mark Complete".
    expect(repo.statuses, contains('InProgress'));
    expect(find.text('Mark Complete'), findsOneWidget);

    await tester.tap(find.text('Mark Complete'));
    await tester.pumpAndSettle();

    expect(repo.statuses, contains('Completed'));
    expect(find.text('This job is marked as completed.'), findsOneWidget);
  });
}

