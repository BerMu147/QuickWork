/// A job-application (worker request) row in the administrator's oversight view.
///
/// Mirrors the backend `JobApplicationResponse` shape used by `GET /JobApplications`.
class AdminJobApplicationModel {
  const AdminJobApplicationModel({
    required this.id,
    required this.jobPostingId,
    required this.jobPostingTitle,
    required this.applicantUserId,
    required this.applicantUserName,
    required this.applicantUserEmail,
    this.message,
    required this.status,
    required this.appliedAt,
    this.respondedAt,
    required this.isActive,
  });

  final int id;
  final int jobPostingId;
  final String jobPostingTitle;
  final int applicantUserId;
  final String applicantUserName;
  final String applicantUserEmail;
  final String? message;
  final String status;
  final DateTime appliedAt;
  final DateTime? respondedAt;
  final bool isActive;

  factory AdminJobApplicationModel.fromJson(Map<String, dynamic> json) {
    return AdminJobApplicationModel(
      id: json['id'] as int? ?? 0,
      jobPostingId: json['jobPostingId'] as int? ?? 0,
      jobPostingTitle: json['jobPostingTitle'] as String? ?? '',
      applicantUserId: json['applicantUserId'] as int? ?? 0,
      applicantUserName: json['applicantUserName'] as String? ?? '',
      applicantUserEmail: json['applicantUserEmail'] as String? ?? '',
      message: json['message'] as String?,
      status: json['status'] as String? ?? '',
      appliedAt: _parseDate(json['appliedAt']),
      respondedAt: _parseOptionalDate(json['respondedAt']),
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) return DateTime.tryParse(value) ?? DateTime(1970);
    if (value is DateTime) return value;
    return DateTime(1970);
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value is String) return DateTime.tryParse(value);
    if (value is DateTime) return value;
    return null;
  }
}
