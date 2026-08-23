// Widget tests + provider unit tests for the Reports module (Phase 2, Item 2).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:quickwork_admin/core/api/api_client.dart';
import 'package:quickwork_admin/features/admin/data/admin_repository.dart';
import 'package:quickwork_admin/features/admin/models/admin_job_posting_model.dart';
import 'package:quickwork_admin/features/admin/models/admin_review_model.dart';
import 'package:quickwork_admin/features/admin/models/category_model.dart';
import 'package:quickwork_admin/features/admin/models/report_models.dart';
import 'package:quickwork_admin/features/admin/models/user_response_model.dart';
import 'package:quickwork_admin/features/admin/providers/admin_provider.dart';
import 'package:quickwork_admin/features/admin/screens/reports_screen.dart';
import 'package:quickwork_admin/features/auth/models/role_model.dart';

void main() {
  setUpAll(() {
    ApiClient.instance.init();
  });

  final role = RoleModel(id: 1, name: 'Worker');
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
      isActive: false,
      createdAt: DateTime(2024, 2, 1),
      genderId: 2,
      genderName: 'Male',
      cityId: 2,
      cityName: 'Mostar',
      roles: const [RoleModel(id: 2, name: 'Publisher')],
    ),
  ];
  final jobs = [
    AdminJobPostingModel(
      id: 1,
      title: 'Plumbing',
      description: 'Fix a leak',
      categoryId: 1,
      categoryName: 'Home',
      postedByUserId: 1,
      postedByUserName: 'Alice Smith',
      postedByUserEmail: 'alice@example.com',
      cityId: 1,
      cityName: 'Sarajevo',
      paymentAmount: 100,
      scheduledDate: DateTime(2024, 3, 1),
      status: 'Open',
      isActive: true,
    ),
    AdminJobPostingModel(
      id: 2,
      title: 'Cleaning',
      description: 'Clean office',
      categoryId: 2,
      categoryName: 'Office',
      postedByUserId: 2,
      postedByUserName: 'Bob Jones',
      postedByUserEmail: 'bob@example.com',
      cityId: 2,
      cityName: 'Mostar',
      paymentAmount: 50,
      scheduledDate: DateTime(2024, 3, 2),
      status: 'Completed',
      isActive: true,
    ),
  ];
  final reviews = [
    AdminReviewModel(
      id: 1,
      jobPostingId: 1,
      jobPostingTitle: 'Plumbing',
      reviewerUserId: 2,
      reviewerUserName: 'Bob Jones',
      reviewedUserId: 1,
      reviewedUserName: 'Alice Smith',
      rating: 5,
      comment: 'Great',
      createdAt: DateTime(2024, 3, 3),
      isActive: true,
    ),
    AdminReviewModel(
      id: 2,
      jobPostingId: 2,
      jobPostingTitle: 'Cleaning',
      reviewerUserId: 1,
      reviewerUserName: 'Alice Smith',
      reviewedUserId: 2,
      reviewedUserName: 'Bob Jones',
      rating: 3,
      comment: 'Okay',
      createdAt: DateTime(2024, 3, 4),
      isActive: true,
    ),
  ];

  final repo = _FakeAdminRepository(
    users: users,
    roles: [role, RoleModel(id: 2, name: 'Publisher')],
    jobs: jobs,
    categories: const [
      CategoryModel(id: 1, name: 'Home', isActive: true),
      CategoryModel(id: 2, name: 'Office', isActive: true),
    ],
    reviews: reviews,
  );

  Widget buildApp(AdminProvider provider) {
    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: provider)],
      child: const MaterialApp(home: ReportsScreen()),
    );
  }

  test('buildCombinedCsv contains headers and rows for all three reports',
      () async {
    final provider = AdminProvider(repository: repo);
    await provider.loadReports();

    final csv = provider.buildCombinedCsv();
    expect(csv, contains('USERS REPORT'));
    expect(csv, contains('Role,Total,Active,Inactive'));
    expect(csv, contains('JOBS REPORT'));
    expect(csv, contains('Status,Count'));
    expect(csv, contains('REVIEWS REPORT'));
    expect(csv, contains('Rating,Count'));
    expect(csv, contains('Home,1'));
  });

  test('loadReports computes correct aggregates', () async {
    final provider = AdminProvider(repository: repo);
    await provider.loadReports();

    final ReportData data = provider.reportData;
    expect(data.totalUsers, 2);
    expect(data.activeUsers, 1);
    expect(data.inactiveUsers, 1);
    expect(data.totalJobs, 2);
    expect(data.totalReviews, 2);
    expect(data.averageRating, closeTo(4.0, 0.001));
  });

  testWidgets('Reports screen renders the Users report tables',
      (tester) async {
    final provider = AdminProvider(repository: repo);
    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    expect(find.text('Reports'), findsOneWidget);
    // Users report is the default tab.
    expect(find.text('Total users'), findsOneWidget);
    expect(find.text('Users by role'), findsOneWidget);
    expect(find.text('Worker'), findsOneWidget);
    expect(find.text('Publisher'), findsOneWidget);
  });

  testWidgets('Reports screen switches tabs across the three reports',
      (tester) async {
    final provider = AdminProvider(repository: repo);
    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    // Switch to the Jobs tab.
    await tester.tap(find.text('Jobs'));
    await tester.pumpAndSettle();
    expect(find.text('Jobs by status'), findsOneWidget);
    expect(find.text('Jobs by category'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);

    // Switch to the Reviews tab.
    await tester.tap(find.text('Reviews'));
    await tester.pumpAndSettle();
    expect(find.text('Reviews by rating'), findsOneWidget);
    expect(find.text('5 stars'), findsOneWidget);
  });

  test('exportReports writes the combined CSV to the given directory',
      () async {
    final provider = AdminProvider(repository: repo);
    await provider.loadReports();

    // Plain (non-widget) test => real async I/O is allowed and will not hang
    // the fake-async zone used by widget tests.
    final dir = await Directory.systemTemp.createTemp('qw_reports');
    await provider.exportReports(exportDirOverride: dir);

    expect(provider.lastExportPath, isNotNull);
    expect(provider.exportMessage, contains('Exported'));
    final file = File(provider.lastExportPath!);
    expect(file.existsSync(), isTrue);
    final contents = await file.readAsString();
    expect(contents, contains('USERS REPORT'));
    expect(contents, contains('JOBS REPORT'));
    expect(contents, contains('REVIEWS REPORT'));
  });
}

/// A fake repository returning fixed report data (no network).
class _FakeAdminRepository extends AdminRepository {
  _FakeAdminRepository({
    required this.users,
    required this.roles,
    required this.jobs,
    required this.categories,
    required this.reviews,
  });

  final List<AdminUserModel> users;
  final List<RoleModel> roles;
  final List<AdminJobPostingModel> jobs;
  final List<CategoryModel> categories;
  final List<AdminReviewModel> reviews;

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
  Future<List<RoleModel>> fetchRoles() async => roles;

  @override
  Future<List<AdminJobPostingModel>> fetchJobPostings({
    String? status,
    int? categoryId,
    String? title,
    int? page,
    int? pageSize,
  }) async =>
      jobs;

  @override
  Future<List<CategoryModel>> fetchCategories() async => categories;

  @override
  Future<List<AdminReviewModel>> fetchReviews({
    int? reviewedUserId,
    int? minRating,
    int? maxRating,
    int? page,
    int? pageSize,
  }) async =>
      reviews;
}
