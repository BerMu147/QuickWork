/// A review left by one user (the reviewer) about another user (the reviewed)
/// for a specific, completed job. Returned by the backend.
class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.jobPostingId,
    required this.jobPostingTitle,
    required this.reviewerUserId,
    required this.reviewerUserName,
    required this.reviewedUserId,
    required this.reviewedUserName,
    required this.rating,
    this.comment,
    this.createdAt,
    this.isActive = true,
  });

  final int id;
  final int jobPostingId;
  final String jobPostingTitle;
  final int reviewerUserId;
  final String reviewerUserName;
  final int reviewedUserId;
  final String reviewedUserName;

  /// Rating from 1 to 5.
  final int rating;
  final String? comment;
  final DateTime? createdAt;
  final bool isActive;

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as int? ?? 0,
      jobPostingId: json['jobPostingId'] as int? ?? 0,
      jobPostingTitle: json['jobPostingTitle'] as String? ?? '',
      reviewerUserId: json['reviewerUserId'] as int? ?? 0,
      reviewerUserName: json['reviewerUserName'] as String? ?? '',
      reviewedUserId: json['reviewedUserId'] as int? ?? 0,
      reviewedUserName: json['reviewedUserName'] as String? ?? '',
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String?,
      createdAt: parseDate(json['createdAt']),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  static DateTime? parseDate(dynamic value) {
    if (value is String) return DateTime.tryParse(value);
    if (value is DateTime) return value;
    return null;
  }
}
