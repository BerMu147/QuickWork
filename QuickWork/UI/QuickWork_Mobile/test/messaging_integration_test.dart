// Integration test for the per-job messaging flow (publisher <-> worker).
import 'package:flutter_test/flutter_test.dart';

import 'package:quickwork_mobile/core/api/api_client.dart';
import 'package:quickwork_mobile/features/auth/data/auth_repository.dart';
import 'package:quickwork_mobile/features/jobs/data/job_posting_repository.dart';
import 'package:quickwork_mobile/features/jobs/data/message_repository.dart';

void main() {
  late ApiClient api;
  late AuthRepository auth;
  late JobPostingRepository jobs;
  late MessageRepository messages;

  setUpAll(() {
    api = ApiClient.instance;
    api.init();
    auth = AuthRepository(apiClient: api);
    jobs = JobPostingRepository(apiClient: api);
    messages = MessageRepository(apiClient: api);
  });

  test('a publisher can send a message about their job to a worker',
      () async {
    // Login as the publisher.
    final login = await auth.login(username: 'berinm', password: 'test');
    expect(login.token, isNotEmpty);
    api.setAuthToken(login.token);

    // Find one of the user's published jobs.
    final myJobs = await jobs.fetchJobsForUser(login.user.id);
    expect(myJobs, isNotEmpty);

    // Pick an applicant (worker) for that job.
    final applicants = await jobs.fetchApplicationsForJob(myJobs[0].id);
    if (applicants.isEmpty) {
      // Without an applicant we don't have a second participant — skip.
      return;
    }
    final worker = applicants
        .where((a) => a.status != 'Withdrawn')
        .firstOrNull;
    final target = worker ?? applicants.first;

    final job = myJobs[0];
    final jobPostingId = job.id;
    final publisherId = login.user.id;
    final workerId = target.applicantUserId;

    // Send a short test message from the publisher to the worker.
    final sent = await messages.sendMessage(
      jobPostingId: jobPostingId,
      senderUserId: publisherId,
      receiverUserId: workerId,
      content: 'Integration test message — please ignore.',
    );
    expect(sent.id, greaterThan(0));

    // Fetch the thread; it must contain the message we just sent.
    final thread = await messages.fetchThread(
      jobPostingId: jobPostingId,
      senderUserId: publisherId,
      receiverUserId: workerId,
    );
    final found = thread.any((m) => m.id == sent.id);
    expect(found, isTrue);
  }, timeout: const Timeout(Duration(seconds: 30)));
}
