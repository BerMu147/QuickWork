import 'user_response_model.dart';

/// Request payload for an administrator to update a user's profile.
///
/// Mirrors the backend `UserUpsertRequest` used by `PUT /Users/{id}`. The
/// backend's `UpdateAsync` replaces roles whenever `RoleIds` is provided, so
/// the full set of role ids (including the current ones) must be carried over
/// on every update to avoid silently wiping role assignments.
class UserUpdatePayload {
  const UserUpdatePayload({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    required this.genderId,
    required this.cityId,
    required this.isActive,
    this.phoneNumber,
    this.bio,
    required this.roleIds,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final int genderId;
  final int cityId;
  final String? phoneNumber;
  final String? bio;
  final bool isActive;
  final List<int> roleIds;

  /// Builds a payload from an existing user, ready to be edited and resent.
  factory UserUpdatePayload.fromUser(AdminUserModel user) {
    return UserUpdatePayload(
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      username: user.username,
      phoneNumber: user.phoneNumber,
      bio: user.bio,
      genderId: user.genderId,
      cityId: user.cityId,
      isActive: user.isActive,
      roleIds: user.roles.map((r) => r.id).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'username': username,
        'phoneNumber': phoneNumber,
        'bio': bio,
        'genderId': genderId,
        'cityId': cityId,
        'isActive': isActive,
        'roleIds': roleIds,
      };
}
