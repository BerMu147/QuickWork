// Integration test for the auth flow against a live backend.
//
// This test hits the real QuickWork API, so it requires:
// - the backend to be running on the machine
// - valid test credentials (berinm / test)
//
// Run with: flutter test test/auth_integration_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:quickwork_mobile/core/api/api_client.dart';
import 'package:quickwork_mobile/core/api/api_exceptions.dart';
import 'package:quickwork_mobile/features/auth/data/auth_repository.dart';

void main() {
  const validUsername = 'berinm';
  const validPassword = 'test';

  setUpAll(() {
    // Prepare the HTTP client (self-signed cert acceptance) before any request.
    ApiClient.instance.init();
  });

  test('login with valid credentials returns a token and user', () async {
    final repo = AuthRepository();
    final login = await repo.login(
      username: validUsername,
      password: validPassword,
    );

    expect(login.token, isNotEmpty);
    expect(login.user.username, validUsername);
    expect(login.user.id, greaterThan(0));
    expect(login.user.fullName, isNotEmpty);
    expect(login.user.cityName, isNotEmpty);

    // The user should carry at least the Administrator role.
    expect(login.user.hasRole('Administrator'), isTrue);
  });

  test('login with wrong password throws ApiException (401)', () async {
    final repo = AuthRepository();
    await expectLater(
      repo.login(username: validUsername, password: 'wrongpass'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 401),
      ),
    );
  });

  test('login with unknown user throws ApiException (401)', () async {
    final repo = AuthRepository();
    await expectLater(
      repo.login(username: 'does_not_exist', password: 'anything'),
      throwsA(isA<ApiException>()),
    );
  });
}

