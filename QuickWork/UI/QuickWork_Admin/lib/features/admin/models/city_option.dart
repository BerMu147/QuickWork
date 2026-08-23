/// A city option selectable when editing a user's profile.
///
/// Mirrors the backend `CityResponse` shape from `GET /City`.
class CityOption {
  const CityOption({required this.id, required this.name});

  final int id;
  final String name;

  factory CityOption.fromJson(Map<String, dynamic> json) {
    return CityOption(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }

  @override
  String toString() => name;
}
