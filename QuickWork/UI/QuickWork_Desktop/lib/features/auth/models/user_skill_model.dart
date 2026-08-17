/// A custom skill added by a user and shown on their profile.
class UserSkillModel {
  const UserSkillModel({
    required this.id,
    required this.userId,
    required this.skillName,
    this.createdAt,
    this.isActive = true,
  });

  final int id;
  final int userId;
  final String skillName;
  final DateTime? createdAt;
  final bool isActive;

  factory UserSkillModel.fromJson(Map<String, dynamic> json) {
    return UserSkillModel(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      skillName: json['skillName'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String) return DateTime.tryParse(value);
    if (value is DateTime) return value;
    return null;
  }
}
