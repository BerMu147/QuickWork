/// Request payload for registering a new user via `POST /Users`.
class RegisterRequest {
  const RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    required this.password,
    required this.genderId,
    required this.cityId,
    this.phoneNumber,
    this.roleIds = const [],
  });

  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final String password;
  final int genderId;
  final int cityId;
  final String? phoneNumber;
  final List<int> roleIds;

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'username': username,
        'password': password,
        'genderId': genderId,
        'cityId': cityId,
        'phoneNumber': phoneNumber,
        'roleIds': roleIds,
        'isActive': true,
      };
}
