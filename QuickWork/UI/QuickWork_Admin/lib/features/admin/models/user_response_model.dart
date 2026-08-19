import '../../auth/models/role_model.dart';

/// Represents a user row in the administrator's user directory.
///
/// Mirrors the backend `UserResponse` shape used by `GET /Users`.
class AdminUserModel {
  const AdminUserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    required this.isActive,
    this.phoneNumber,
    this.bio,
    required this.createdAt,
    this.lastLoginAt,
    required this.genderId,
    required this.genderName,
    required this.cityId,
    required this.cityName,
    this.roles = const [],
  });

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final bool isActive;
  final String? phoneNumber;
  final String? bio;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final int genderId;
  final String genderName;
  final int cityId;
  final String cityName;
  final List<RoleModel> roles;

  String get fullName => '$firstName $lastName'.trim();

  bool hasRole(String roleName) =>
      roles.any((r) => r.name.toLowerCase() == roleName.toLowerCase());

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id'] as int? ?? 0,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      phoneNumber: json['phoneNumber'] as String?,
      bio: json['bio'] as String?,
      createdAt: _parseDate(json['createdAt']),
      lastLoginAt: _parseDateNullable(json['lastLoginAt']),
      genderId: json['genderId'] as int? ?? 0,
      genderName: json['genderName'] as String? ?? '',
      cityId: json['cityId'] as int? ?? 0,
      cityName: json['cityName'] as String? ?? '',
      roles: (json['roles'] as List<dynamic>? ?? [])
          .map((r) => RoleModel.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) return DateTime.tryParse(value) ?? DateTime(1970);
    if (value is DateTime) return value;
    return DateTime(1970);
  }

  static DateTime? _parseDateNullable(dynamic value) {
    if (value is String) return DateTime.tryParse(value);
    if (value is DateTime) return value;
    return null;
  }
}
