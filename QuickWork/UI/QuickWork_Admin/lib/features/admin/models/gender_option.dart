/// A gender option selectable when editing a user's profile.
///
/// Mirrors the backend `GenderResponse` shape from `GET /Gender`.
class GenderOption {
  const GenderOption({required this.id, required this.name});

  final int id;
  final String name;

  factory GenderOption.fromJson(Map<String, dynamic> json) {
    return GenderOption(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }

  @override
  String toString() => name;
}
