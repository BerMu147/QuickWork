/// Payload for creating a notification.
///
/// Mirrors the backend `NotificationUpsertRequest` used by `POST /Notifications`.
class NotificationPayload {
  const NotificationPayload({
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedEntityType,
    this.relatedEntityId,
  });

  final int userId;
  final String type;
  final String title;
  final String message;
  final String? relatedEntityType;
  final int? relatedEntityId;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'type': type,
        'title': title,
        'message': message,
        if (relatedEntityType != null) 'relatedEntityType': relatedEntityType,
        if (relatedEntityId != null) 'relatedEntityId': relatedEntityId,
      };
}
