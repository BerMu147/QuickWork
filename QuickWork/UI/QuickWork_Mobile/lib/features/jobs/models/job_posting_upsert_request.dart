/// Request payload for creating a job posting via `POST /JobPostings`.
class JobPostingUpsertRequest {
  const JobPostingUpsertRequest({
    required this.title,
    required this.description,
    required this.categoryId,
    required this.cityId,
    this.address,
    required this.paymentAmount,
    this.estimatedDurationHours,
    required this.scheduledDate,
    this.scheduledTimeStart,
    this.scheduledTimeEnd,
    this.status = 'Open',
    this.isActive = true,
  });

  final String title;
  final String description;
  final int categoryId;
  final int cityId;
  final String? address;
  final double paymentAmount;
  final double? estimatedDurationHours;
  final DateTime scheduledDate;
  final String? scheduledTimeStart;
  final String? scheduledTimeEnd;
  final String status;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'cityId': cityId,
      'address': address,
      'paymentAmount': paymentAmount,
      'estimatedDurationHours': estimatedDurationHours,
      'scheduledDate': _formatDate(scheduledDate),
      'scheduledTimeStart': scheduledTimeStart,
      'scheduledTimeEnd': scheduledTimeEnd,
      'status': status,
      'isActive': isActive,
    };
  }

  static String _formatDate(DateTime d) {
    // Backend expects ISO datetime, e.g. 2026-03-01T00:00:00.
    final y = d.year.toString().padLeft(4, '0');
    final mo = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$mo-${day}T00:00:00';
  }
}
