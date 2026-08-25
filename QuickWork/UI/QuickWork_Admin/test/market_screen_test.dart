// Widget tests + provider unit tests for the Market / Analytics module
// (Phase 2, Item 7).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:quickwork_admin/core/api/api_client.dart';
import 'package:quickwork_admin/features/admin/data/admin_repository.dart';
import 'package:quickwork_admin/features/admin/models/admin_job_application_model.dart';
import 'package:quickwork_admin/features/admin/models/admin_job_posting_model.dart';
import 'package:quickwork_admin/features/admin/models/category_model.dart';
import 'package:quickwork_admin/features/admin/models/market_analytics_model.dart';
import 'package:quickwork_admin/features/admin/models/user_response_model.dart';
import 'package:quickwork_admin/features/admin/providers/admin_provider.dart';
import 'package:quickwork_admin/features/admin/screens/market_screen.dart';
import 'package:quickwork_admin/features/auth/models/role_model.dart';

void main() {
  setUpAll(() {
    ApiClient.instance.init();
  });

  final role = RoleModel(id: 1, name: 'Worker');
  final publisherRole = RoleModel(id: 2, name: 'Publisher');

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
    AdminUserModel(
      id: 3,
      firstName: 'Carol',
      lastName: 'Lee',
      email: 'carol@example.com',
      username: 'carol',
      isActive: true,
      createdAt: DateTime(2024, 3, 1),
      genderId: 1,
      genderName: 'Female',
      cityId: 1,
      cityName: 'Sarajevo',
      roles: const [RoleModel(id: 1, name: 'Worker')],
    ),
  ];

  final jobs = [
    // Open job with 0 applications -> underserved.
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
    // Open job with 1 application (the application below).
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
      status: 'Open',
      isActive: true,
    ),
    // Completed job, not open.
    AdminJobPostingModel(
      id: 3,
      title: 'Gardening',
      description: 'Mow lawn',
      categoryId: 1,
      categoryName: 'Home',
      postedByUserId: 1,
      postedByUserName: 'Alice Smith',
      postedByUserEmail: 'alice@example.com',
      cityId: 1,
      cityName: 'Sarajevo',
      paymentAmount: 40,
      scheduledDate: DateTime(2024, 3, 3),
      status: 'Completed',
      isActive: true,
    ),
  ];

  final applications = [
    AdminJobApplicationModel(
      id: 1,
      jobPostingId: 2,
      jobPostingTitle: 'Cleaning',
      applicantUserId: 1,
      applicantUserName: 'Alice Smith',
      applicantUserEmail: 'alice@example.com',
      status: 'Pending',
      appliedAt: DateTime(2024, 3, 4),
      isActive: true,
    ),
    AdminJobApplicationModel(
      id: 2,
      jobPostingId: 2,
      jobPostingTitle: 'Cleaning',
      applicantUserId: 3,
      applicantUserName: 'Carol Lee',
      applicantUserEmail: 'carol@example.com',
      status: 'Accepted',
      appliedAt: DateTime(2024, 3, 5),
      isActive: true,
    ),
  ];

  final repo = _FakeAdminRepository(
    users: users,
    roles: [role, publisherRole],
    jobs: jobs,
    categories: const [
      CategoryModel(id: 1, name: 'Home', isActive: true),
      CategoryModel(id: 2, name: 'Office', isActive: true),
    ],
    applications: applications,
  );

  Widget buildApp(AdminProvider provider) {
    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: provider)],
      child: const MaterialApp(home: MarketScreen()),
    );
  }

  test('loadMarketAnalytics computes matching metrics', () async {
    final provider = AdminProvider(repository: repo);
    await provider.loadMarketAnalytics();

    final MarketAnalyticsData data = provider.marketAnalytics;
    // Open jobs: id=1 and id=2 (id=3 is Completed).
    expect(data.totalOpenJobs, 2);
    expect(data.totalApplications, 2);
    expect(data.pendingApplications, 1);
    expect(data.acceptedApplications, 1);
    expect(data.rejectedApplications, 0);
    // Active workers: Alice (1) + Carol (3); Bob is Publisher + inactive.
    expect(data.activeWorkers, 2);
    // Average applications per open job = 2 / 2 = 1.0.
    expect(data.averageApplicationsPerOpenJob, closeTo(1.0, 0.001));
  });

  test('underserved demand flags only open jobs with no applicants', () async {
    final provider = AdminProvider(repository: repo);
    await provider.loadMarketAnalytics();

    final rows = provider.marketAnalytics.underServedJobs;
    // Job id=1 (Plumbing, open, 0 apps) is underserved.
    expect(rows, hasLength(1));
    expect(rows.first.title, 'Plumbing');
    expect(rows.first.applicationCount, 0);
  });

  test('category and city demand are computed correctly', () async {
    final provider = AdminProvider(repository: repo);
    await provider.loadMarketAnalytics();

    final byCat = provider.marketAnalytics.categoryDemand;
    // Home: jobs 1 (open) + 3 (completed) = 2 total, 1 open, apps for jobs in
    // Home = 0 (both apps target id=2 Office).
    final home = byCat.firstWhere((c) => c.category == 'Home');
    expect(home.totalJobs, 2);
    expect(home.openJobs, 1);
    expect(home.applications, 0);
    final office = byCat.firstWhere((c) => c.category == 'Office');
    expect(office.totalJobs, 1);
    expect(office.openJobs, 1);
    expect(office.applications, 2);

    final byCity = provider.marketAnalytics.cityDemand;
    final sarajevo = byCity.firstWhere((c) => c.city == 'Sarajevo');
    expect(sarajevo.openJobs, 1);
    expect(sarajevo.totalJobs, 2);
    final mostar = byCity.firstWhere((c) => c.city == 'Mostar');
    expect(mostar.openJobs, 1);
    expect(mostar.totalJobs, 1);
  });

  testWidgets('Market screen renders KPIs and section headers', (tester) async {
    final provider = AdminProvider(repository: repo);
    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    expect(find.text('Market / Analytics'), findsOneWidget);
    expect(find.text('Open Jobs'), findsOneWidget);
    expect(find.text('Applications'), findsOneWidget);
    expect(find.text('Active Workers'), findsOneWidget);
    expect(find.text('Underserved demand (open jobs with no applicants)'),
        findsOneWidget);
    expect(find.text('Demand by category'), findsOneWidget);
    expect(find.text('Demand by city'), findsOneWidget);
    expect(find.text('Labor supply (active workers)'), findsOneWidget);
    // Underserved job title visible.
    expect(find.text('Plumbing'), findsOneWidget);
  });

  testWidgets('Application status breakdown reflects counts', (tester) async {
    final provider = AdminProvider(repository: repo);
    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    expect(find.text('Application status'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
  });
}

/// A fake repository returning fixed market data (no network).
class _FakeAdminRepository extends AdminRepository {
  _FakeAdminRepository({
    required this.users,
    required this.roles,
    required this.jobs,
    required this.categories,
    required this.applications,
  });

  final List<AdminUserModel> users;
  final List<RoleModel> roles;
  final List<AdminJobPostingModel> jobs;
  final List<CategoryModel> categories;
  final List<AdminJobApplicationModel> applications;

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
  Future<List<AdminJobApplicationModel>> fetchJobApplications({
    int? jobPostingId,
    int? applicantUserId,
    String? status,
    int? page,
    int? pageSize,
  }) async =>
      applications;

  @override
  Future<List<CategoryModel>> fetchCategories() async => categories;
}
