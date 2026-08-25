// Widget tests + provider unit tests for the Support Tickets module
// (Phase 2, Item 11).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:quickwork_admin/core/api/api_client.dart';
import 'package:quickwork_admin/features/admin/data/admin_repository.dart';
import 'package:quickwork_admin/features/admin/models/admin_support_ticket_model.dart';
import 'package:quickwork_admin/features/admin/models/support_ticket_payloads.dart';
import 'package:quickwork_admin/features/admin/providers/admin_provider.dart';
import 'package:quickwork_admin/features/admin/screens/support_screen.dart';

void main() {
  setUpAll(() {
    ApiClient.instance.init();
  });

  Widget buildApp(AdminProvider provider) {
    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: provider)],
      child: const MaterialApp(home: SupportScreen()),
    );
  }

  final tickets = [
    AdminSupportTicketModel(
      id: 1,
      userId: 2,
      userName: 'Bob Jones',
      userEmail: 'bob@example.com',
      subject: 'Cannot log in',
      message: 'I get an error when trying to log in.',
      category: 'Bug',
      priority: 'High',
      status: 'Open',
      createdAt: DateTime(2024, 3, 1),
      isActive: true,
    ),
    AdminSupportTicketModel(
      id: 2,
      userId: 3,
      userName: 'Carol Lee',
      userEmail: 'carol@example.com',
      subject: 'Payment question',
      message: 'When will my payment arrive?',
      category: 'Question',
      priority: 'Medium',
      status: 'Resolved',
      adminReply: 'Payment is scheduled for Friday.',
      createdAt: DateTime(2024, 3, 2),
      isActive: true,
    ),
  ];

  test('Loads tickets and exposes them through the provider', () async {
    final provider = AdminProvider(repository: _FakeAdminRepository(tickets));
    await provider.loadSupportTickets();

    expect(provider.supportTickets, hasLength(2));
    expect(provider.supportTickets.first.subject, 'Cannot log in');
    expect(provider.supportTicketsError, isNull);
  });

  testWidgets('Support screen renders ticket rows and status', (tester) async {
    final provider = AdminProvider(repository: _FakeAdminRepository(tickets));
    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    expect(find.text('Support Tickets'), findsOneWidget);
    expect(find.text('Cannot log in'), findsOneWidget);
    expect(find.text('Payment question'), findsOneWidget);
    // Status appears both in the filter chips and on the ticket badges.
    expect(find.text('Open'), findsWidgets);
    expect(find.text('Resolved'), findsWidgets);
    // The resolved ticket shows its admin reply.
    expect(find.textContaining('Payment is scheduled for Friday.'),
        findsOneWidget);
  });

  testWidgets('Filtering by status shows only matching tickets', (tester) async {
    final provider = AdminProvider(repository: _FakeAdminRepository(tickets));
    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Resolved'));
    await tester.pumpAndSettle();

    expect(find.text('Payment question'), findsOneWidget);
    expect(find.text('Cannot log in'), findsNothing);
  });

  testWidgets('Replying to a ticket updates its status and stores the reply',
      (tester) async {
    final provider = AdminProvider(repository: _FakeAdminRepository(tickets));
    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    // Open the reply dialog for the open ticket.
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reply / Resolve'));
    await tester.pumpAndSettle();

    expect(find.text('Resolve ticket'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Write the resolution note of the administrator...'),
      'We are working on it.',
    );
    await tester.tap(find.text('Send reply'));
    await tester.pumpAndSettle();

    // The open ticket moved to Resolved with the admin reply shown.
    expect(provider.supportTickets.first.status, 'Resolved');
    expect(
      provider.supportTickets.first.adminReply,
      'We are working on it.',
    );
    expect(find.text('Ticket resolved with your reply.'), findsOneWidget);
  });

  testWidgets('Deleting a ticket removes it and shows confirmation',
      (tester) async {
    final provider = AdminProvider(repository: _FakeAdminRepository(tickets));
    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete ticket'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(provider.supportTickets, hasLength(1));
    expect(find.text('Cannot log in'), findsNothing);
    expect(find.text('Payment question'), findsOneWidget);
  });
}

/// A fake repository returning fixed tickets and applying reply/status/delete
/// mutations in memory.
class _FakeAdminRepository extends AdminRepository {
  _FakeAdminRepository(this.tickets);

  List<AdminSupportTicketModel> tickets;

  @override
  Future<List<AdminSupportTicketModel>> fetchSupportTickets({
    int? userId,
    String? status,
    String? priority,
    String? category,
    int? page,
    int? pageSize,
  }) async {
    return tickets
        .where((t) => status == null || status.isEmpty || t.status == status)
        .toList();
  }

  @override
  Future<AdminSupportTicketModel> replySupportTicket(
    int id,
    SupportTicketReplyPayload payload,
  ) async {
    final index = tickets.indexWhere((t) => t.id == id);
    final current = tickets[index];
    final target = payload.status ?? 'Resolved';
    final updated = current.copyWith(
      status: target,
      adminReply: payload.adminReply,
    );
    tickets[index] = updated;
    return updated;
  }

  @override
  Future<AdminSupportTicketModel> updateSupportTicketStatus(
    int id,
    SupportTicketStatusPayload payload,
  ) async {
    final index = tickets.indexWhere((t) => t.id == id);
    final updated = tickets[index].copyWith(status: payload.status);
    tickets[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteSupportTicket(int id) async {
    tickets = tickets.where((t) => t.id != id).toList();
  }
}
