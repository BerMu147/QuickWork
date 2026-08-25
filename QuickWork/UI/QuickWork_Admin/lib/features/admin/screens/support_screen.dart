import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../models/admin_support_ticket_model.dart';
import '../providers/admin_provider.dart';

/// Support / help-desk screen of the administrator console (Item 11).
///
/// Lets an administrator browse user-raised tickets, filter by lifecycle
/// status, write a resolution reply (advancing the status), update the status
/// directly and soft-delete a ticket.
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String? _selectedStatus;

  static const List<String> _statuses = [
    'Open',
    'InProgress',
    'Resolved',
    'Closed',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      if (admin.supportTickets.isEmpty && !admin.isLoadingSupportTickets) {
        admin.loadSupportTickets();
      }
    });
  }

  Future<void> _load() async {
    await context
        .read<AdminProvider>()
        .loadSupportTickets(status: _selectedStatus);
  }

  Future<void> _openReply(AdminSupportTicketModel ticket) async {
    final messenger = ScaffoldMessenger.of(context);
    final admin = context.read<AdminProvider>();

    final result = await showDialog<_ReplyResult>(
      context: context,
      builder: (context) => _ReplyDialog(ticket: ticket),
    );

    if (result == null) return;

    final reply = result.reply.trim();
    if (reply.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('A reply is required to resolve a ticket.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await admin.replyToSupportTicket(ticket, reply);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Ticket ${result.status.toLowerCase()} with your reply.'
              : 'Failed to reply to the ticket.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _changeStatus(AdminSupportTicketModel ticket, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    final admin = context.read<AdminProvider>();
    final success = await admin.updateSupportTicketStatus(ticket, status);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Ticket moved to $status.'
              : 'Failed to update the ticket status.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _confirmAndDelete(AdminSupportTicketModel ticket) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete ticket'),
        content: Text(
          'Delete ticket "${ticket.subject}"? It will be hidden from the '
          'support queue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final admin = context.read<AdminProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await admin.deleteSupportTicket(ticket);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Ticket deleted.' : 'Failed to delete ticket.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Tickets'),
        backgroundColor: AppConstants.primary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in _statuses)
                  ChoiceChip(
                    label: Text(status),
                    selected: _selectedStatus == status,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = selected ? status : null;
                      });
                      _load();
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: admin.isLoadingSupportTickets &&
                    admin.supportTickets.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : admin.supportTicketsError != null &&
                        admin.supportTickets.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                admin.supportTicketsError!,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _load,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : admin.supportTickets.isEmpty
                        ? const Center(child: Text('No support tickets.'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount: admin.supportTickets.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final ticket = admin.supportTickets[index];
                                return _SupportTicketTile(
                                  ticket: ticket,
                                  onReply: () => _openReply(ticket),
                                  onStatus: (status) =>
                                      _changeStatus(ticket, status),
                                  onDelete: () => _confirmAndDelete(ticket),
                                  deleting: admin.isDeletingSupportTicket,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

/// The result returned by the reply dialog: the written reply + desired status.
class _ReplyResult {
  const _ReplyResult({required this.reply, required this.status});

  final String reply;
  final String status;
}

class _ReplyDialog extends StatefulWidget {
  const _ReplyDialog({required this.ticket});

  final AdminSupportTicketModel ticket;

  @override
  State<_ReplyDialog> createState() => _ReplyDialogState();
}

class _ReplyDialogState extends State<_ReplyDialog> {
  static const List<String> _statuses = [
    'Resolved',
    'Open',
    'InProgress',
    'Closed',
  ];
  late final TextEditingController _replyController;
  String _status = 'Resolved';

  @override
  void initState() {
    super.initState();
    _replyController = TextEditingController(
      text: widget.ticket.adminReply ?? '',
    );
    // Default the new status to Resolved unless already resolved/closed.
    if (widget.ticket.status == 'Resolved' ||
        widget.ticket.status == 'Closed') {
      _status = widget.ticket.status;
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    return AlertDialog(
      title: const Text('Resolve ticket'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ticket.subject,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'From ${ticket.userName} (${ticket.userEmail})',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Text('Issue:', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(ticket.message),
            const SizedBox(height: 16),
            const Text(
              'Your reply:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _replyController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Write the resolution note of the administrator...',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'New status:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: _status,
              items: _statuses
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (value) {
                setState(() => _status = value ?? _status);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(
              _ReplyResult(reply: _replyController.text, status: _status),
            );
          },
          child: const Text('Send reply'),
        ),
      ],
    );
  }
}

class _SupportTicketTile extends StatelessWidget {
  const _SupportTicketTile({
    required this.ticket,
    required this.onReply,
    required this.onStatus,
    required this.onDelete,
    required this.deleting,
  });

  final AdminSupportTicketModel ticket;
  final VoidCallback onReply;
  final ValueChanged<String> onStatus;
  final VoidCallback onDelete;
  final bool deleting;

  static const List<String> _statuses = [
    'Open',
    'InProgress',
    'Resolved',
    'Closed',
  ];

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(ticket.status);
    final priorityColor = _priorityColor(ticket.priority);
    final createdDate = DateFormat.yMMMd().format(ticket.createdAt);

    final replyExists = ticket.adminReply != null &&
        ticket.adminReply!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.subject,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ticket.userName} · $createdDate',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Badge(text: ticket.category, color: Colors.blueGrey),
                        _Badge(text: ticket.priority, color: priorityColor),
                        _Badge(text: ticket.status, color: statusColor),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Ticket actions',
                onSelected: (value) {
                  switch (value) {
                    case 'reply':
                      onReply();
                    case 'delete':
                      onDelete();
                    default:
                      if (value != ticket.status) onStatus(value);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'reply',
                    child: Text('Reply / Resolve'),
                  ),
                  const PopupMenuDivider(),
                  for (final s in _statuses)
                    PopupMenuItem(
                      value: s,
                      enabled: s != ticket.status,
                      child: Text('Set status: $s'),
                    ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            ticket.message,
            style: const TextStyle(fontSize: 14),
          ),
          if (replyExists) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '✓ ${ticket.adminReply!.trim()}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF2E7D32)),
              ),
            ),
          ],
          if (deleting) const SizedBox(height: 4),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.red;
      case 'inprogress':
        return const Color(0xFFFF9800);
      case 'resolved':
        return const Color(0xFF4CAF50);
      case 'closed':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return const Color(0xFFFF9800);
      case 'medium':
        return const Color(0xFF129ACA);
      case 'low':
        return const Color(0xFF4CAF50);
      default:
        return Colors.blueGrey;
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
