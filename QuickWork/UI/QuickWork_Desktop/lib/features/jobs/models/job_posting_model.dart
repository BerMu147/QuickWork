/// A job posting returned by the backend.
class JobPostingModel {
  const JobPostingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.postedByUserId,
    required this.postedByUserName,
    required this.postedByUserEmail,
    required this.cityId,
    required this.cityName,
    this.address,
    required this.paymentAmount,
    this.estimatedDurationHours,
    required this.scheduledDate,
    this.scheduledTimeStart,
    this.scheduledTimeEnd,
    required this.status,
    required this.isActive,
    this.applicationCount = 0,
    this.messageCount = 0,
  });

  final int id;
  final String title;
  final String description;
  final int categoryId;
  final String categoryName;
  final int postedByUserId;
  final String postedByUserName;
  final String postedByUserEmail;
  final int cityId;
  final String cityName;
  final String? address;
  final double paymentAmount;
  final double? estimatedDurationHours;
  final DateTime scheduledDate;
  final String? scheduledTimeStart;
  final String? scheduledTimeEnd;
  final String status;
  final bool isActive;
  final int applicationCount;
  final int messageCount;

  bool get isOpen => status.toLowerCase() == 'open';

  factory JobPostingModel.fromJson(Map<String, dynamic> json) {
    return JobPostingModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      categoryId: json['categoryId'] as int? ?? 0,
      categoryName: json['categoryName'] as String? ?? '',
      postedByUserId: json['postedByUserId'] as int? ?? 0,
      postedByUserName: json['postedByUserName'] as String? ?? '',
      postedByUserEmail: json['postedByUserEmail'] as String? ?? '',
      cityId: json['cityId'] as int? ?? 0,
      cityName: json['cityName'] as String? ?? '',
      address: json['address'] as String?,
      paymentAmount: (json['paymentAmount'] as num?)?.toDouble() ?? 0,
      estimatedDurationHours:
          (json['estimatedDurationHours'] as num?)?.toDouble(),
      scheduledDate: _parseDate(json['scheduledDate']),
      scheduledTimeStart: json['scheduledTimeStart'] as String?,
      scheduledTimeEnd: json['scheduledTimeEnd'] as String?,
      status: json['status'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
      applicationCount: json['applicationCount'] as int? ?? 0,
      messageCount: json['messageCount'] as int? ?? 0,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime(1970);
    }
    if (value is DateTime) return value;
    return DateTime(1970);
  }
}
