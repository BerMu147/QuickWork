/// Request payload for submitting a job application via `POST /JobApplications`.
class JobApplicationRequest {
  const JobApplicationRequest({
    required this.jobPostingId,
    this.message,
    this.status = 'Pending',
    this.isActive = true,
  });

  final int jobPostingId;
  final String? message;
  final String status;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'jobPostingId': jobPostingId,
        'message': message,
        'status': status,
        'isActive': isActive,
      };
}
