import 'user_response_model.dart';

/// Request payload for updating a user's active status.
///
/// Mirrors the backend `UserUpsertRequest`. Because the backend's `UpdateAsync`
/// replaces roles whenever `RoleIds` is provided, every field (including the
/// current [RoleIds]) must be carried over so a simple activate/deactivate
/// toggle does not wipe role assignments or other profile data.
class UserActivationPayload {
  const UserActivationPayload({
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
  final String? phoneNumber;
  final String? bio;
  final int genderId;
  final int cityId;
  final bool isActive;
  final List<int> roleIds;

  /// Builds a payload from an existing user row, applying [newIsActive].
  factory UserActivationPayload.fromUser(
    AdminUserModel user, {
    required bool newIsActive,
  }) {
    return UserActivationPayload(
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      username: user.username,
      phoneNumber: user.phoneNumber,
      bio: user.bio,
      genderId: user.genderId,
      cityId: user.cityId,
      isActive: newIsActive,
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
