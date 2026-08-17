/// A city that a user can select (e.g. for registration or job location).
class CityModel {
  const CityModel({required this.id, required this.name});

  final int id;
  final String name;

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }

  @override
  String toString() => name;
}
