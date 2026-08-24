// Widget tests + provider unit tests for the Notifications module (Phase 2, Item 3).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:quickwork_admin/core/api/api_client.dart';
import 'package:quickwork_admin/features/admin/data/admin_repository.dart';
import 'package:quickwork_admin/features/admin/models/notification_model.dart';
import 'package:quickwork_admin/features/admin/models/notification_payload.dart';
import 'package:quickwork_admin/features/admin/models/user_response_model.dart';
import 'package:quickwork_admin/features/admin/providers/admin_provider.dart';
import 'package:quickwork_admin/features/admin/screens/notifications_screen.dart';
import 'package:quickwork_admin/features/auth/models/role_model.dart';

void main() {
  setUpAll(() {
    ApiClient.instance.init();
  });

  final users = [
    AdminUserModel(
      id: 1,
      firstName: 'Alice',
      lastName: 'Smith',
      email: 'alice@example.com',
      username: 'alice',
      isActive: true,
      createdAt: DateTime(2024, 1, 1),
      genderId: 1,
      genderName: 'Female',
      cityId: 1,
      cityName: 'Sarajevo',
      roles: const [RoleModel(id: 1, name: 'Worker')],
    ),
    AdminUserModel(
      id: 2,
      firstName: 'Bob',
      lastName: 'Jones',
      email: 'bob@example.com',
      username: 'bob',
      isActive: true,
      createdAt: DateTime(2024, 2, 1),
      genderId: 2,
      genderName: 'Male',
      cityId: 2,
      cityName: 'Mostar',
      roles: const [RoleModel(id: 2, name: 'Publisher')],
    ),
  ];

  Widget buildApp(AdminProvider provider) {
    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: provider)],
      child: const MaterialApp(home: NotificationsScreen()),
    );
  }

  testWidgets('Notifications screen shows compose card and empty history',
      (tester) async {
    final provider = AdminProvider(
      repository: _FakeAdminRepository(users: users, history: const []),
    );
    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Send announcement to all users'), findsOneWidget);
    expect(find.text('No notifications sent yet.'), findsOneWidget);
  });

  testWidgets('Sending an announcement fans out to every user', (tester) async {
    final repo = _FakeAdminRepository(users: users, history: const []);
    final provider = AdminProvider(repository: repo);
    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Title'),
      'Maintenance',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Message'),
      'Downtime at 22:00.',
    );
    await tester.tap(find.text('Send to all users'));
    await tester.pumpAndSettle();

    // Every user received one notification.
    expect(repo.createdByUserId, [1, 2]);
    expect(provider.sendMessage, contains('Announcement sent to 2 user(s)'));
    expect(provider.notifications.length, 2);
    expect(find.text('Maintenance'), findsWidgets);
  });

  testWidgets('Validation prevents sending an empty announcement',
      (tester) async {
    final repo = _FakeAdminRepository(users: users, history: const []);
    final provider = AdminProvider(repository: repo);
    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send to all users'));
    await tester.pumpAndSettle();

    expect(repo.createdByUserId, isEmpty);
    expect(
      find.text('Please provide both a title and a message.'),
      findsOneWidget,
    );
  });

  testWidgets('History shows notifications and delete removes one',
      (tester) async {
    final history = [
      AdminNotificationModel(
        id: 1,
        userId: 2,
        type: 'announcement',
        title: 'Old notice',
        message: 'Services resumed.',
        isRead: false,
        createdAt: DateTime(2024, 1, 1),
      ),
    ];
    final repo = _FakeAdminRepository(users: users, history: history);
    final provider = AdminProvider(repository: repo);
    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    expect(find.text('Old notice'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Old notice'), findsNothing);
  });
}

/// A fake repository that records created notifications and returns fixed
/// user + history data.
class _FakeAdminRepository extends AdminRepository {
  _FakeAdminRepository({
    required this.users,
    required this.history,
  });

  final List<AdminUserModel> users;
  List<AdminNotificationModel> history;
  final List<int> createdByUserId = [];

  @override
  Future<List<AdminUserModel>> fetchUsers({
    String? username,
    String? email,
    int? roleId,
    int? page,
    int? pageSize,
  }) async =>
      users;

  @override
  Future<List<AdminNotificationModel>> fetchNotifications({
    int? userId,
    int? page,
    int? pageSize,
  }) async =>
      history;

  @override
  Future<AdminNotificationModel> createNotification(
    NotificationPayload payload,
  ) async {
    createdByUserId.add(payload.userId);
    final notification = AdminNotificationModel(
      id: 1000 + payload.userId,
      userId: payload.userId,
      type: payload.type,
      title: payload.title,
      message: payload.message,
      isRead: false,
      createdAt: DateTime.now(),
    );
    history = [notification, ...history];
    return notification;
  }

  @override
  Future<void> deleteNotification(int id) async {
    history = history.where((n) => n.id != id).toList();
  }
}
