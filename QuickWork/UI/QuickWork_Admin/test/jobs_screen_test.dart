// Widget tests + provider unit tests for job moderation (Phase 2, Item 2-LITE):
// the admin view + delete of user-posted jobs.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:quickwork_admin/core/api/api_client.dart';
import 'package:quickwork_admin/features/admin/data/admin_repository.dart';
import 'package:quickwork_admin/features/admin/models/admin_job_posting_model.dart';
import 'package:quickwork_admin/features/admin/providers/admin_provider.dart';
import 'package:quickwork_admin/features/admin/screens/jobs_screen.dart';

void main() {
  setUpAll(() {
    ApiClient.instance.init();
  });

  AdminJobPostingModel job(int id, String title) => AdminJobPostingModel(
        id: id,
        title: title,
        description: 'Description of $title',
        categoryId: 1,
        categoryName: 'Repairs',
        postedByUserId: 2,
        postedByUserName: 'bob',
        postedByUserEmail: 'bob@example.com',
        cityId: 1,
        cityName: 'Sarajevo',
        paymentAmount: 500,
        scheduledDate: DateTime(2024, 5, 10),
        status: 'Open',
        isActive: true,
        applicationCount: 3,
      );

  Widget buildApp(AdminProvider provider) {
    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: provider)],
      child: const MaterialApp(home: JobsScreen()),
    );
  }

  testWidgets('Job rows show a delete action', (tester) async {
    final provider = AdminProvider(
      repository: _FakeAdminRepository(
        jobs: [job(1, 'Fix the roof'), job(2, 'Paint the fence')],
      ),
    );
    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    expect(find.text('Fix the roof'), findsOneWidget);
    expect(find.text('Paint the fence'), findsOneWidget);
    // Every row has a delete affordance.
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
  });

  testWidgets('Delete shows a confirmation dialog first', (tester) async {
    final provider = AdminProvider(
      repository: _FakeAdminRepository(jobs: [job(1, 'Fix the roof')]),
    );
    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Delete job'), findsOneWidget);
    expect(find.textContaining('cannot be undone'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Cancelling closes the dialog and keeps the row.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Fix the roof'), findsOneWidget);
    expect(provider.jobs.length, 1);
  });

  testWidgets('Confirming delete removes the job from the list',
      (tester) async {
    final provider = AdminProvider(
      repository: _FakeAdminRepository(
        jobs: [job(1, 'Fix the roof'), job(2, 'Paint the fence')],
      ),
    );
    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    // Delete the first job.
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Only the second job remains.
    expect(provider.jobs.length, 1);
    expect(provider.jobs.first.id, 2);
    expect(find.text('Fix the roof'), findsNothing);
    expect(find.text('Paint the fence'), findsOneWidget);
  });

  testWidgets('Failed delete keeps the row and shows an error',
      (tester) async {
    final provider = AdminProvider(
      repository: _FakeAdminRepository(
        jobs: [job(1, 'Fix the roof')],
        failDelete: true,
      ),
    );
    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Row kept + error surfaced.
    expect(provider.jobs.length, 1);
    expect(provider.jobDeleteError, isNotNull);
    expect(find.text('Fix the roof'), findsOneWidget);
    expect(find.text('Failed to delete job.'), findsOneWidget);
  });
}

/// In-memory fake repository that returns fixed job postings and optionally
/// fails deletions.
class _FakeAdminRepository extends AdminRepository {
  _FakeAdminRepository({
    required this.jobs,
    this.failDelete = false,
  });

  final List<AdminJobPostingModel> jobs;
  final bool failDelete;

  @override
  Future<List<AdminJobPostingModel>> fetchJobPostings({
    String? status,
    int? categoryId,
    String? title,
    int? page,
    int? pageSize,
  }) async {
    if (status != null && status.isNotEmpty) {
      return jobs
          .where((j) => j.status.toLowerCase() == status.toLowerCase())
          .toList();
    }
    return jobs;
  }

  @override
  Future<void> deleteJob(int id) async {
    if (failDelete) {
      throw Exception('delete failed');
    }
  }
}
