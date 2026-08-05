import 'role_model.dart';

/// Authenticated user details returned by the backend.
class UserModel {
  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    this.picture,
    this.isActive = true,
    this.phoneNumber,
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
  final String? picture;
  final bool isActive;
  final String? phoneNumber;
  final int genderId;
  final String genderName;
  final int cityId;
  final String cityName;
  final List<RoleModel> roles;

  String get fullName => '$firstName $lastName'.trim();

  /// Whether the user has at least one of the given [roleNames].
  bool hasRole(String roleName) =>
      roles.any((r) => r.name.toLowerCase() == roleName.toLowerCase());

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      picture: json['picture'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      phoneNumber: json['phoneNumber'] as String?,
      genderId: json['genderId'] as int? ?? 0,
      genderName: json['genderName'] as String? ?? '',
      cityId: json['cityId'] as int? ?? 0,
      cityName: json['cityName'] as String? ?? '',
      roles: (json['roles'] as List<dynamic>? ?? [])
          .map((r) => RoleModel.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}
