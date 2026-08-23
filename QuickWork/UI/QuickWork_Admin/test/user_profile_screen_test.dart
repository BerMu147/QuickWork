// Widget tests for the administrator user-profile detail/edit screen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:quickwork_admin/core/api/api_client.dart';
import 'package:quickwork_admin/features/admin/data/admin_repository.dart';
import 'package:quickwork_admin/features/admin/models/city_option.dart';
import 'package:quickwork_admin/features/admin/models/gender_option.dart';
import 'package:quickwork_admin/features/admin/models/user_response_model.dart';
import 'package:quickwork_admin/features/admin/models/user_update_payload.dart';
import 'package:quickwork_admin/features/admin/providers/admin_provider.dart';
import 'package:quickwork_admin/features/admin/screens/user_profile_screen.dart';
import 'package:quickwork_admin/features/auth/models/role_model.dart';

void main() {
  setUpAll(() {
    ApiClient.instance.init();
  });

  final user = AdminUserModel(
    id: 1,
    firstName: 'Alice',
    lastName: 'Smith',
    email: 'alice@example.com',
    username: 'alice',
    isActive: true,
    phoneNumber: '555-0100',
    bio: 'Worker from Sarajevo',
    createdAt: DateTime(2024, 1, 1),
    genderId: 1,
    genderName: 'Female',
    cityId: 1,
    cityName: 'Sarajevo',
    roles: const [RoleModel(id: 1, name: 'Worker')],
  );

  Widget buildApp(AdminProvider provider) {
    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: provider)],
      child: MaterialApp(
        home: UserProfileScreen(userId: user.id),
      ),
    );
  }

  testWidgets('User profile screen shows full user details', (tester) async {
    final provider = AdminProvider(repository: _FakeAdminRepository(user));
    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    expect(find.text('Alice Smith'), findsOneWidget);
    expect(find.text('@alice'), findsOneWidget);
    expect(find.textContaining('alice@example.com'), findsOneWidget);
    expect(find.textContaining('555-0100'), findsOneWidget);
    expect(find.text('City: Sarajevo'), findsOneWidget);
    expect(find.text('Gender: Female'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Worker'), findsOneWidget);
    expect(find.textContaining('Worker from Sarajevo'), findsOneWidget);
  });

  testWidgets('Edit sheet pre-fills fields and saves updates', (tester) async {
    final provider = AdminProvider(repository: _FakeAdminRepository(user));
    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Edit profile'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();

    // Bottom-sheet form is shown with pre-filled values.
    expect(find.text('Edit user profile'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Alice'), findsOneWidget);

    // Edit the first name and save.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Alice'),
      'Alicia',
    );
    await tester.scrollUntilVisible(
      find.text('Save'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // The update persists back to the provider / detail.
    final savedUser = provider.userDetail;
    expect(savedUser, isNotNull);
    expect(savedUser!.firstName, 'Alicia');
  });
}

/// A fake repository returning the provided user and fixed lookup options.
class _FakeAdminRepository extends AdminRepository {
  _FakeAdminRepository(this.user);

  AdminUserModel user;

  @override
  Future<AdminUserModel> fetchUserById(int id) async => user;

  @override
  Future<List<GenderOption>> fetchGenders() async => const [
        GenderOption(id: 1, name: 'Female'),
        GenderOption(id: 2, name: 'Male'),
      ];

  @override
  Future<List<CityOption>> fetchCities() async => const [
        CityOption(id: 1, name: 'Sarajevo'),
        CityOption(id: 2, name: 'Mostar'),
      ];

  @override
  Future<List<RoleModel>> fetchRoles() async => const [
        RoleModel(id: 1, name: 'Worker'),
        RoleModel(id: 2, name: 'Publisher'),
        RoleModel(id: 3, name: 'Administrator'),
      ];

  @override
  Future<AdminUserModel> updateUser({
    required int userId,
    required UserUpdatePayload payload,
  }) async {
    user = AdminUserModel(
      id: userId,
      firstName: payload.firstName,
      lastName: payload.lastName,
      email: payload.email,
      username: payload.username,
      isActive: payload.isActive,
      phoneNumber: payload.phoneNumber,
      bio: payload.bio,
      createdAt: user.createdAt,
      genderId: payload.genderId,
      genderName: user.genderName,
      cityId: payload.cityId,
      cityName: user.cityName,
      roles: const [RoleModel(id: 1, name: 'Worker')],
    );
    return user;
  }
}
