// Integration tests for backend application validation rules.
//
// Requires the backend running with the new validation applied (restart the
// backend after rebuilding so the ownership + duplicate rules take effect).
//   1. A publisher cannot apply to their own job.
//   2. A user cannot apply to the same job more than once.
import 'package:flutter_test/flutter_test.dart';

import 'package:quickwork_mobile/core/api/api_client.dart';
import 'package:quickwork_mobile/features/auth/data/auth_repository.dart';
import 'package:quickwork_mobile/features/jobs/data/job_posting_repository.dart';

/// Returns true if [ex] is an API/user error carrying [fragment].
bool _hasMessage(Object? ex, String fragment) =>
    (ex?.toString() ?? '').contains(fragment);

void main() {
  late ApiClient api;
  late AuthRepository auth;
  late JobPostingRepository jobs;

  setUpAll(() {
    api = ApiClient.instance;
    api.init();
    auth = AuthRepository(apiClient: api);
    jobs = JobPostingRepository(apiClient: api);
  });

  test('a publisher cannot apply to their own job', () async {
    // Login as berinm (seed user id 1) and fetch one of their own postings.
    final login = await auth.login(username: 'berinm', password: 'test');
    api.setAuthToken(login.token);

    final myJobs = await jobs.fetchJobsForUser(login.user.id);
    expect(myJobs, isNotEmpty);

    // Applying to one's own posting must be rejected with a clear message.
    await expectLater(
      jobs.applyToJob(
        jobPostingId: myJobs.first.id,
        applicantUserId: login.user.id,
        message: 'Should be blocked.',
      ),
      throwsA(predicate((e) => _hasMessage(e, 'apply to your own job'))),
    );
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('a worker cannot apply to the same job twice', () async {
    // Login as a worker. Seed data already has Lepa (user 3) applied to job 1
    // ("Potreban babysitter", posted by Goran), so a fresh application to job 1
    // must be rejected as a duplicate.
    final login = await auth.login(username: 'lepal', password: 'test');
    api.setAuthToken(login.token);

    await expectLater(
      jobs.applyToJob(
        jobPostingId: 1,
        applicantUserId: login.user.id,
        message: 'This is a duplicate.',
      ),
      throwsA(predicate((e) => _hasMessage(e, 'already applied'))),
    );
  }, timeout: const Timeout(Duration(seconds: 30)));
}

