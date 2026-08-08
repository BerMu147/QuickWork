// Integration tests for the job posting repository against a live backend.
import 'package:flutter_test/flutter_test.dart';

import 'package:quickwork_mobile/core/api/api_client.dart';
import 'package:quickwork_mobile/features/auth/data/auth_repository.dart';
import 'package:quickwork_mobile/features/jobs/data/job_posting_repository.dart';

void main() {
  late ApiClient api;
  late AuthRepository auth;

  setUpAll(() {
    api = ApiClient.instance;
    api.init();
    auth = AuthRepository(apiClient: api);
  });

  test('fetches job postings when authenticated', () async {
    // Log in to get a bearer token.
    final login = await auth.login(username: 'berinm', password: 'test');
    expect(login.token, isNotEmpty);
    api.setAuthToken(login.token);

    final repo = JobPostingRepository(apiClient: api);
    final jobs = await repo.fetchJobPostings();

    expect(jobs, isNotEmpty);
    final first = jobs.first;
    expect(first.title, isNotEmpty);
    expect(first.cityName, isNotEmpty);
    expect(first.categoryName, isNotEmpty);
    expect(first.paymentAmount, greaterThanOrEqualTo(0));
  });
}

