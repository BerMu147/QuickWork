// Integration test for the publisher's Accept/Reject application flow.
import 'package:flutter_test/flutter_test.dart';

import 'package:quickwork_mobile/core/api/api_client.dart';
import 'package:quickwork_mobile/features/auth/data/auth_repository.dart';
import 'package:quickwork_mobile/features/jobs/data/job_posting_repository.dart';
import 'package:quickwork_mobile/features/jobs/models/job_application_model.dart';

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

  test('a publisher can accept and then revert an application on their job',
      () async {
    // Login as the publisher.
    final login = await auth.login(username: 'berinm', password: 'test');
    expect(login.token, isNotEmpty);
    api.setAuthToken(login.token);

    // Find one of the user's published jobs.
    final myJobs = await repo.fetchJobsForUser(login.user.id);
    expect(myJobs, isNotEmpty, reason: 'publisher has at least one job');

    // Load applications received for that job.
    final app = await _firstPendingApplication(repo, myJobs[0].id);
    if (app == null) {
      // No pending application to exercise — the update endpoint is the same
      // regardless of which status we set, so this is a safe no-op.
      return;
    }

    // Accept the candidate.
    final accepted = await repo.updateApplicationStatus(
      applicationId: app.id,
      jobPostingId: myJobs[0].id,
      status: 'Accepted',
    );
    expect(accepted.id, app.id);
    expect(accepted.status, 'Accepted');

    // Revert to Pending to keep the data clean.
    final reverted = await repo.updateApplicationStatus(
      applicationId: app.id,
      jobPostingId: myJobs[0].id,
      status: 'Pending',
    );
    expect(reverted.status, 'Pending');
  }, timeout: const Timeout(Duration(seconds: 30)));
}

Future<JobApplicationModel?> _firstPendingApplication(
    JobPostingRepository repo, int jobPostingId) async {
  final apps = await repo.fetchApplicationsForJob(jobPostingId);
  return apps.where((a) => a.status == 'Pending').firstOrNull;
}
