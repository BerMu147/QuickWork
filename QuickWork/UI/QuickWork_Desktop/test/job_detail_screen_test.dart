// Widget tests for the Job Detail screen's apply-button states.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickwork_desktop/core/api/api_client.dart';
import 'package:quickwork_desktop/features/auth/data/auth_repository.dart';
import 'package:quickwork_desktop/features/auth/models/login_response.dart';
import 'package:quickwork_desktop/features/auth/models/user_model.dart';
import 'package:quickwork_desktop/features/auth/providers/auth_provider.dart';
import 'package:quickwork_desktop/features/jobs/data/job_posting_repository.dart';
import 'package:quickwork_desktop/features/jobs/models/job_application_model.dart';
import 'package:quickwork_desktop/features/jobs/models/job_posting_model.dart';
import 'package:quickwork_desktop/features/jobs/providers/job_posting_provider.dart';
import 'package:quickwork_desktop/features/jobs/screens/job_detail_screen.dart';

class _FakeAuthRepo extends AuthRepository {
  @override
  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    return LoginResponse(token: 'fake.token', user: _user);
  }

  UserModel get user => _user;
}

final _user = UserModel(
  id: 5,
  firstName: 'Berin',
  lastName: 'M',
  email: 'berin@test.com',
  username: 'berinm',
  genderId: 1,
  genderName: 'Male',
  cityId: 1,
  cityName: 'Sarajevo',
  phoneNumber: '061000000',
  roles: const [],
);

// A job posted by a DIFFERENT user (id 7), so user 5 is an applicant.
final _otherJob = JobPostingModel.fromJson(const {
  'id': 1,
  'title': 'Fix the roof',
  'description': 'Need a roofer.',
  'cityId': 1,
  'cityName': 'Sarajevo',
  'categoryId': 1,
  'categoryName': 'Construction',
  'paymentAmount': 100,
  'status': 'Open',
  'postedByUserId': 7,
  'postedByUserName': 'Owner',
  'scheduledDate': '2025-01-01',
});

// A job posted by user 5 themself (the publisher).
final _ownJob = JobPostingModel.fromJson(const {
  'id': 2,
  'title': 'My own job',
  'description': 'Published by me.',
  'cityId': 1,
  'cityName': 'Sarajevo',
  'categoryId': 1,
  'categoryName': 'Construction',
  'paymentAmount': 80,
  'status': 'Open',
  'postedByUserId': 5,
  'postedByUserName': 'Berin M',
  'scheduledDate': '2025-01-02',
});

class _FakeJobRepo extends JobPostingRepository {
  final JobPostingModel? existingAppForJob;
  final JobPostingModel? job;
  _FakeJobRepo({this.existingAppForJob, this.job});

  @override
  Future<List<JobPostingModel>> fetchJobPostings(
      [JobPostingQuery? query]) async {
    return job == null ? [] : [job!];
  }

  @override
  Future<List<JobApplicationModel>> fetchApplicationsForUser(
      int applicantUserId) async {
    if (existingAppForJob != null) {
      return [
        JobApplicationModel(
          id: 1,
          jobPostingId: existingAppForJob!.id,
          jobPostingTitle: existingAppForJob!.title,
          applicantUserId: applicantUserId,
          applicantUserName: 'Berin M',
          applicantUserEmail: 'berin@test.com',
          message: null,
          status: 'Pending',
          appliedAt: DateTime(2025, 1, 1),
          isActive: true,
        ),
      ];
    }
    return [];
  }
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.instance.init();
  });

  Future<void> pump(WidgetTester tester,
      {JobPostingRepository? repo, JobPostingModel? job}) async {
    final auth = AuthProvider(repository: _FakeAuthRepo());
    await auth.login(username: 'berinm', password: 'test');
    final fakeRepo = repo ?? _FakeJobRepo();
    final jobProvider = JobPostingProvider(repository: fakeRepo);
    // Populate the provider's job list so byId() returns the job.
    await jobProvider.loadJobPostings();

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<JobPostingProvider>.value(value: jobProvider),
      ],
      child: MaterialApp(home: JobDetailScreen(jobId: job!.id)),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('owner does not see an Apply button', (tester) async {
    await pump(tester,
        repo: _FakeJobRepo(job: _ownJob), job: _ownJob);

    expect(find.text('This is your job posting'), findsOneWidget);
    expect(find.text('Apply for this job'), findsNothing);
    // No message-to-self button either.
    expect(find.text('Message the publisher'), findsNothing);
  });

  testWidgets('an applicant who already applied sees their status',
      (tester) async {
    await pump(tester,
        repo: _FakeJobRepo(existingAppForJob: _otherJob, job: _otherJob),
        job: _otherJob);

    expect(find.text('Application Pending'), findsOneWidget);
    expect(find.text('Apply for this job'), findsNothing);
  });
}

