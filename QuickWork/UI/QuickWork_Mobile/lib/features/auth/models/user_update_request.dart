/// Request payload for updating a user via `PUT /Users/{id}`.
class UserUpdateRequest {
  const UserUpdateRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    required this.genderId,
    required this.cityId,
    this.phoneNumber,
    this.picture,
    required this.isActive,
    this.roleIds = const [],
  });

  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final int genderId;
  final int cityId;
  final String? phoneNumber;
  final List<int>? picture; // byte[] (image) — kept null for now.
  final bool isActive;
  final List<int> roleIds;

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'username': username,
      'genderId': genderId,
      'cityId': cityId,
      'phoneNumber': phoneNumber,
      'picture': picture,
      'isActive': isActive,
      'roleIds': roleIds,
    };
  }
}
