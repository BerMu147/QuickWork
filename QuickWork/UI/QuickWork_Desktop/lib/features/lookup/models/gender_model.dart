/// A gender option a user can select during registration.
class GenderModel {
  const GenderModel({required this.id, required this.name});

  final int id;
  final String name;

  factory GenderModel.fromJson(Map<String, dynamic> json) {
    return GenderModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }

  @override
  String toString() => name;
}
