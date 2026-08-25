// Payloads for creating and replying to support tickets.
//
// Mirrors the backend `SupportTicketUpsertRequest` and
// `SupportTicketReplyRequest` shapes.

/// Payload for `POST /SupportTickets` (a user filing a new ticket).
class SupportTicketCreatePayload {
  const SupportTicketCreatePayload({
    required this.userId,
    required this.subject,
    required this.message,
    required this.category,
    required this.priority,
  });

  final int userId;
  final String subject;
  final String message;
  final String category;
  final String priority;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'subject': subject,
        'message': message,
        'category': category,
        'priority': priority,
      };
}

/// Payload for `PATCH /SupportTickets/{id}/reply` (admin resolving a ticket).
class SupportTicketReplyPayload {
  const SupportTicketReplyPayload({
    required this.adminReply,
    this.status,
  });

  final String adminReply;

  /// Optional new status to apply (Open, InProgress, Resolved, Closed).
  final String? status;

  Map<String, dynamic> toJson() => {
        'adminReply': adminReply,
        if (status != null) 'status': status,
      };
}

/// Payload for `PATCH /SupportTickets/{id}/status` (status-only update).
class SupportTicketStatusPayload {
  const SupportTicketStatusPayload({required this.status});

  final String status;

  Map<String, dynamic> toJson() => {'status': status};
}
