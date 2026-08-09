// Integration test for user profile update against a live backend.
import 'package:flutter_test/flutter_test.dart';

import 'package:quickwork_mobile/core/api/api_client.dart';
import 'package:quickwork_mobile/features/auth/data/auth_repository.dart';
import 'package:quickwork_mobile/features/auth/data/user_repository.dart';
import 'package:quickwork_mobile/features/auth/models/user_update_request.dart';

void main() {
  late ApiClient api;
  late AuthRepository auth;
  late UserRepository repo;

  setUpAll(() {
    api = ApiClient.instance;
    api.init();
    auth = AuthRepository(apiClient: api);
    repo = UserRepository(apiClient: api);
  });

  test('a logged-in user can update their profile', () async {
    final login = await auth.login(username: 'berinm', password: 'test');
    expect(login.token, isNotEmpty);
    api.setAuthToken(login.token);

    // Save the original phone so we can restore it afterwards.
    final original = login.user;

    final request = UserUpdateRequest(
      firstName: original.firstName,
      lastName: original.lastName,
      email: original.email,
      username: original.username,
      genderId: original.genderId,
      cityId: original.cityId,
      phoneNumber: '000000000', // temporary test value
      isActive: true,
      roleIds: original.roles.map((r) => r.id).toList(),
    );

    final updated = await repo.updateUser(id: original.id, request: request);
    expect(updated.id, original.id);
    expect(updated.firstName, original.firstName);
    expect(updated.phoneNumber, '000000000');

    // Restore the original phone number to keep data clean.
    final restoreRequest = UserUpdateRequest(
      firstName: original.firstName,
      lastName: original.lastName,
      email: original.email,
      username: original.username,
      genderId: original.genderId,
      cityId: original.cityId,
      phoneNumber: original.phoneNumber,
      isActive: true,
      roleIds: original.roles.map((r) => r.id).toList(),
    );
    await repo.updateUser(id: original.id, request: restoreRequest);
  }, timeout: const Timeout(Duration(seconds: 30)));
}
