// Integration tests for the job publishing flow against a live backend.
import 'package:flutter_test/flutter_test.dart';

import 'package:quickwork_mobile/core/api/api_client.dart';
import 'package:quickwork_mobile/features/auth/data/auth_repository.dart';
import 'package:quickwork_mobile/features/jobs/data/job_posting_repository.dart';
import 'package:quickwork_mobile/features/jobs/models/job_posting_upsert_request.dart';

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

  test('logged-in user can publish a job posting', () async {
    // Log in to get a token.
    final login = await auth.login(username: 'berinm', password: 'test');
    expect(login.token, isNotEmpty);
    api.setAuthToken(login.token);

    // Fetch categories & cities to build a valid request.
    final categories = await repo.fetchCategories();
    expect(categories, isNotEmpty);

    final tomorrow = DateTime.now().add(const Duration(days: 5));

    final request = JobPostingUpsertRequest(
      title: 'Integration test job',
      description: 'Auto-generated test posting.',
      categoryId: categories.first.id,
      cityId: 1, // Sarajevo
      address: 'Test address',
      paymentAmount: 100,
      estimatedDurationHours: 3,
      scheduledDate: tomorrow,
      scheduledTimeStart: '09:00:00',
      scheduledTimeEnd: '12:00:00',
    );

    // Publish the job.
    final created = await repo.createJobPosting(
      request: request,
      postedByUserId: login.user.id,
    );

    expect(created.id, greaterThan(0));
    expect(created.title, 'Integration test job');
    expect(created.paymentAmount, 100);
    expect(created.postedByUserId, login.user.id);

    // Clean up: delete the test posting.
    final deleted = await api.dio.delete<void>('/JobPostings/${created.id}');
    expect(deleted.statusCode, 204);
  }, timeout: const Timeout(Duration(seconds: 30)));
}
