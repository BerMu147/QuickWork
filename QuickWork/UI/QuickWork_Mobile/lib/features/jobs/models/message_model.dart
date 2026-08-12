/// A message exchanged between a publisher and a worker for a job.
class MessageModel {
  const MessageModel({
    required this.id,
    required this.jobPostingId,
    required this.jobPostingTitle,
    required this.senderUserId,
    required this.senderUserName,
    required this.receiverUserId,
    required this.receiverUserName,
    required this.content,
    required this.sentAt,
    this.isRead = false,
  });

  final int id;
  final int jobPostingId;
  final String jobPostingTitle;
  final int senderUserId;
  final String senderUserName;
  final int receiverUserId;
  final String receiverUserName;
  final String content;
  final DateTime sentAt;
  final bool isRead;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as int? ?? 0,
      jobPostingId: json['jobPostingId'] as int? ?? 0,
      jobPostingTitle: json['jobPostingTitle'] as String? ?? '',
      senderUserId: json['senderUserId'] as int? ?? 0,
      senderUserName: json['senderUserName'] as String? ?? '',
      receiverUserId: json['receiverUserId'] as int? ?? 0,
      receiverUserName: json['receiverUserName'] as String? ?? '',
      content: json['content'] as String? ?? '',
      sentAt: _parseDate(json['sentAt']),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal() ?? DateTime(1970);
    }
    if (value is DateTime) return value.toLocal();
    return DateTime(1970);
  }
}
