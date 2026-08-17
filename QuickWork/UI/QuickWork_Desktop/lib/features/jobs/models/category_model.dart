/// A job category (e.g. Babysitter, Electrician) returned by the backend.
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  final int id;
  final String name;
  final bool isActive;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
