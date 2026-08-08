// Integration tests for the job application flow against a live backend.
import 'package:flutter_test/flutter_test.dart';

import 'package:quickwork_mobile/core/api/api_client.dart';
import 'package:quickwork_mobile/features/auth/data/auth_repository.dart';
import 'package:quickwork_mobile/features/jobs/data/job_posting_repository.dart';

void main() {
  late ApiClient api;
  late AuthRepository auth;
  late JobPostingRepository repo;

  setUpAll(() {
    api = ApiClient.instance;
    api.init();
    auth = AuthRepository(apiClient: api);
    repo = JobPostingRepository(apiClient: api);
  });

  test('logged-in user can apply to a job', () async {
    // Log in to get a token.
    final login = await auth.login(username: 'berinm', password: 'test');
    expect(login.token, isNotEmpty);
    api.setAuthToken(login.token);

    // Fetch an open job to apply to.
    final jobs = await repo.fetchJobPostings();
    expect(jobs, isNotEmpty);
    final job = jobs.firstWhere(
      (j) => j.isOpen && j.postedByUserId != login.user.id,
      orElse: () => jobs.first,
    );

    // Submit an application.
    final application = await repo.applyToJob(
      jobPostingId: job.id,
      applicantUserId: login.user.id,
      message: 'Integration test application.',
    );

    expect(application.id, greaterThan(0));
    expect(application.jobPostingId, job.id);
    expect(application.applicantUserId, login.user.id);
    expect(application.status, 'Pending');

    // Clean up: delete the application we just created.
    final deleted = await api.dio.delete<void>(
      '/JobApplications/${application.id}',
    );
    expect(deleted.statusCode, 204);
  }, timeout: const Timeout(Duration(seconds: 30)));
}
