// Widget tests for the publisher's review-applications screen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickwork_mobile/core/api/api_client.dart';
import 'package:quickwork_mobile/features/jobs/data/job_posting_repository.dart';
import 'package:quickwork_mobile/features/jobs/models/job_application_model.dart';
import 'package:quickwork_mobile/features/jobs/models/job_posting_model.dart';
import 'package:quickwork_mobile/features/jobs/providers/job_posting_provider.dart';
import 'package:quickwork_mobile/features/jobs/screens/review_applications_screen.dart';

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
        ChangeNotifierProvider<JobPostingProvider>.value(value: provider),
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
}
