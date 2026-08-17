/// A job application returned by the backend.
class JobApplicationModel {
  const JobApplicationModel({
    required this.id,
    required this.jobPostingId,
    required this.jobPostingTitle,
    required this.applicantUserId,
    required this.applicantUserName,
    required this.applicantUserEmail,
    this.message,
    required this.status,
    this.appliedAt,
    this.isActive = true,
  });

  final int id;
  final int jobPostingId;
  final String jobPostingTitle;
  final int applicantUserId;
  final String applicantUserName;
  final String applicantUserEmail;
  final String? message;
  final String status;
  final DateTime? appliedAt;
  final bool isActive;

  factory JobApplicationModel.fromJson(Map<String, dynamic> json) {
    return JobApplicationModel(
      id: json['id'] as int? ?? 0,
      jobPostingId: json['jobPostingId'] as int? ?? 0,
      jobPostingTitle: json['jobPostingTitle'] as String? ?? '',
      applicantUserId: json['applicantUserId'] as int? ?? 0,
      applicantUserName: json['applicantUserName'] as String? ?? '',
      applicantUserEmail: json['applicantUserEmail'] as String? ?? '',
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'Pending',
      appliedAt: _parseDate(json['appliedAt']),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is DateTime) return value;
    return null;
  }
}
