/// A support / help-desk ticket in the administrator console.
///
/// Mirrors the backend `SupportTicketResponse` shape used by `GET
/// /SupportTickets` (Phase 2, Item 11).
class AdminSupportTicketModel {
  const AdminSupportTicketModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.subject,
    required this.message,
    required this.category,
    required this.priority,
    required this.status,
    this.adminReply,
    required this.createdAt,
    this.updatedAt,
    required this.isActive,
  });

  final int id;
  final int userId;
  final String userName;
  final String userEmail;
  final String subject;
  final String message;
  final String category;
  final String priority;
  final String status;
  final String? adminReply;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  factory AdminSupportTicketModel.fromJson(Map<String, dynamic> json) {
    return AdminSupportTicketModel(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      userName: json['userName'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      message: json['message'] as String? ?? '',
      category: json['category'] as String? ?? '',
      priority: json['priority'] as String? ?? '',
      status: json['status'] as String? ?? '',
      adminReply: json['adminReply'] as String?,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDateNullable(json['updatedAt']),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  AdminSupportTicketModel copyWith({
    String? status,
    String? adminReply,
  }) {
    return AdminSupportTicketModel(
      id: id,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      subject: subject,
      message: message,
      category: category,
      priority: priority,
      status: status ?? this.status,
      adminReply: adminReply ?? this.adminReply,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) return DateTime.tryParse(value) ?? DateTime(1970);
    if (value is DateTime) return value;
    return DateTime(1970);
  }

  static DateTime? _parseDateNullable(dynamic value) {
    if (value is String) return DateTime.tryParse(value);
    if (value is DateTime) return value;
    return null;
  }
}
