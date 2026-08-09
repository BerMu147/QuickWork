// Integration test for the "My Jobs" data flow against a live backend.
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

  test('a logged-in user can fetch their posted jobs and applications', () async {
    final login = await auth.login(username: 'berinm', password: 'test');
    expect(login.token, isNotEmpty);
    api.setAuthToken(login.token);

    // Fetch the jobs this user has published.
    final myJobs = await repo.fetchJobsForUser(login.user.id);

    // Publishers are allowed to fetch user data regardless of whether they
    // have posted anything; ensure the call returned without error.
    expect(myJobs, isA<List<dynamic>>());

    // Fetch the applications this user has submitted.
    final myApps = await repo.fetchApplicationsForUser(login.user.id);
    expect(myApps, isA<List<dynamic>>());
    for (final app in myApps) {
      expect(app.applicantUserId, login.user.id);
    }
  }, timeout: const Timeout(Duration(seconds: 30)));
}
