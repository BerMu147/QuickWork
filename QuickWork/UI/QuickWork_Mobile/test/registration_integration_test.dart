// Integration tests for user registration against a live backend.
//
// Requires the backend running and reachable. Uses a unique username per run
// so repeated test executions don't clash.
import 'package:flutter_test/flutter_test.dart';

import 'package:quickwork_mobile/core/api/api_client.dart';
import 'package:quickwork_mobile/core/api/api_exceptions.dart';
import 'package:quickwork_mobile/features/auth/data/auth_repository.dart';
import 'package:quickwork_mobile/features/auth/models/register_request.dart';
import 'package:quickwork_mobile/features/lookup/data/lookup_repository.dart';

void main() {
  setUpAll(() {
    ApiClient.instance.init();
  });

  test('registration post /Users creates a user and can log in', () async {
    final auth = AuthRepository();
    final lookup = LookupRepository();

    final genders = await lookup.fetchGenders();
    final cities = await lookup.fetchCities();
    expect(genders, isNotEmpty, reason: 'genders should load');
    expect(cities, isNotEmpty, reason: 'cities should load');

    final male = genders.firstWhere((g) => g.name == 'Male', orElse: () => genders.first);
    final city = cities.first;

    final stamp = DateTime.now().millisecondsSinceEpoch;
    final username = 'demo_$stamp';
    final email = 'demo_$stamp@example.com';

    // 1. Register the user.
    final created = await auth.register(
      RegisterRequest(
        firstName: 'Demo',
        lastName: 'User',
        email: email,
        username: username,
        password: 'test',
        genderId: male.id,
        cityId: city.id,
        phoneNumber: '+38760000000',
      ),
    );

    expect(created.id, greaterThan(0));
    expect(created.username, username);
    expect(created.email, email);
    expect(created.cityName, isNotEmpty);

    // 2. Log in immediately with the new credentials.
    final login = await auth.login(username: username, password: 'test');
    expect(login.token, isNotEmpty);
    expect(login.user.username, username);
  });

  test('registration rejects an existing username', () async {
    final auth = AuthRepository();
    await expectLater(
      auth.register(
        const RegisterRequest(
          firstName: 'Dup',
          lastName: 'User',
          email: 'dup@example.com',
          username: 'berinm', // already exists
          password: 'test',
          genderId: 1,
          cityId: 1,
        ),
      ),
      throwsA(isA<ApiException>()),
    );
  });
}
