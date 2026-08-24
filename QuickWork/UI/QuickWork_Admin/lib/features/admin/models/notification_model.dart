/// A row in the administrator's notification history.
///
/// Mirrors the backend `NotificationResponse` shape used by `GET /Notifications`.
class AdminNotificationModel {
  const AdminNotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedEntityType,
    this.relatedEntityId,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  final int id;
  final int userId;
  final String type;
  final String title;
  final String message;
  final String? relatedEntityType;
  final int? relatedEntityId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  factory AdminNotificationModel.fromJson(Map<String, dynamic> json) {
    return AdminNotificationModel(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      relatedEntityType: json['relatedEntityType'] as String?,
      relatedEntityId: json['relatedEntityId'] as int?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: _parseDate(json['createdAt']),
      readAt: _parseDateNullable(json['readAt']),
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
