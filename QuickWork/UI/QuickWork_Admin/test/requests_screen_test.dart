// Widget tests + provider unit tests for job-application oversight
// (Phase 2, Items 5 & 6): admin view of worker requests + delete moderation.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:quickwork_admin/core/api/api_client.dart';
import 'package:quickwork_admin/features/admin/data/admin_repository.dart';
import 'package:quickwork_admin/features/admin/models/admin_job_application_model.dart';
import 'package:quickwork_admin/features/admin/providers/admin_provider.dart';
import 'package:quickwork_admin/features/admin/screens/requests_screen.dart';

void main() {
  setUpAll(() {
    ApiClient.instance.init();
  });

  AdminJobApplicationModel request(int id, String applicant, String status) =>
      AdminJobApplicationModel(
        id: id,
        jobPostingId: 10,
        jobPostingTitle: 'Fix the roof',
        applicantUserId: 5,
        applicantUserName: applicant,
        applicantUserEmail: '$applicant@example.com',
        message: 'I can take this job.',
        status: status,
        appliedAt: DateTime(2024, 5, 10),
        isActive: true,
      );

  Widget buildApp(AdminProvider provider) {
    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: provider)],
      child: const MaterialApp(home: RequestsScreen()),
    );
  }

  testWidgets('Request rows show a delete action and filter by status',
      (tester) async {
    final provider = AdminProvider(
      repository: _FakeAdminRepository(
        requests: [
          request(1, 'alice', 'Pending'),
          request(2, 'bob', 'Accepted'),
        ],
      ),
    );
    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    expect(find.text('alice'), findsOneWidget);
    expect(find.text('bob'), findsOneWidget);
    // Every row has a delete affordance.
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));

    // Filtering by a status happens via the repository.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Accepted'));
    await tester.pumpAndSettle();
    expect(provider.jobApplications.length, 1);
    expect(provider.jobApplications.first.applicantUserName, 'bob');
  });

  testWidgets('Delete shows a confirmation dialog first; cancel keeps row',
      (tester) async {
    final provider = AdminProvider(
      repository: _FakeAdminRepository(requests: [request(1, 'alice', 'Pending')]),
    );
    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Delete request'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('alice'), findsOneWidget);
    expect(provider.jobApplications.length, 1);
  });

  testWidgets('Confirming delete removes the request from the list',
      (tester) async {
    final provider = AdminProvider(
      repository: _FakeAdminRepository(
        requests: [
          request(1, 'alice', 'Pending'),
          request(2, 'bob', 'Pending'),
        ],
      ),
    );
    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(provider.jobApplications.length, 1);
    expect(provider.jobApplications.first.id, 2);
    expect(find.text('alice'), findsNothing);
    expect(find.text('bob'), findsOneWidget);
  });

  testWidgets('Failed delete keeps the row and shows an error',
      (tester) async {
    final provider = AdminProvider(
      repository: _FakeAdminRepository(
        requests: [request(1, 'alice', 'Pending')],
        failDelete: true,
      ),
    );
    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(provider.jobApplications.length, 1);
    expect(provider.jobApplicationDeleteError, isNotNull);
    expect(find.text('alice'), findsOneWidget);
    expect(find.text('Failed to delete request.'), findsOneWidget);
  });
}

/// In-memory fake repository that returns fixed requests and optionally
/// filters by status or fails deletions.
class _FakeAdminRepository extends AdminRepository {
  _FakeAdminRepository({
    required this.requests,
    this.failDelete = false,
  });

  final List<AdminJobApplicationModel> requests;
  final bool failDelete;

  @override
  Future<List<AdminJobApplicationModel>> fetchJobApplications({
    int? jobPostingId,
    int? applicantUserId,
    String? status,
    int? page,
    int? pageSize,
  }) async {
    if (status != null && status.isNotEmpty) {
      return requests
          .where((a) => a.status.toLowerCase() == status.toLowerCase())
          .toList();
    }
    return requests;
  }

  @override
  Future<void> deleteJobApplication(int id) async {
    if (failDelete) {
      throw Exception('delete failed');
    }
  }
}
