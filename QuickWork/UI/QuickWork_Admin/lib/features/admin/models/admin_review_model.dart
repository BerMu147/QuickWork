/// A review row in the administrator's moderation view.
///
/// Mirrors the backend `ReviewResponse` shape used by `GET /Reviews`.
class AdminReviewModel {
  const AdminReviewModel({
    required this.id,
    required this.jobPostingId,
    required this.jobPostingTitle,
    required this.reviewerUserId,
    required this.reviewerUserName,
    required this.reviewedUserId,
    required this.reviewedUserName,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.isActive,
  });

  final int id;
  final int jobPostingId;
  final String jobPostingTitle;
  final int reviewerUserId;
  final String reviewerUserName;
  final int reviewedUserId;
  final String reviewedUserName;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final bool isActive;

  factory AdminReviewModel.fromJson(Map<String, dynamic> json) {
    return AdminReviewModel(
      id: json['id'] as int? ?? 0,
      jobPostingId: json['jobPostingId'] as int? ?? 0,
      jobPostingTitle: json['jobPostingTitle'] as String? ?? '',
      reviewerUserId: json['reviewerUserId'] as int? ?? 0,
      reviewerUserName: json['reviewerUserName'] as String? ?? '',
      reviewedUserId: json['reviewedUserId'] as int? ?? 0,
      reviewedUserName: json['reviewedUserName'] as String? ?? '',
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String?,
      createdAt: _parseDate(json['createdAt']),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) return DateTime.tryParse(value) ?? DateTime(1970);
    if (value is DateTime) return value;
    return DateTime(1970);
  }
}
