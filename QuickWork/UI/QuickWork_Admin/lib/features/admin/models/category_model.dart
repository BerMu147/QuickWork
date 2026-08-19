/// A job category (used for the job-offer / job-demand overview).
///
/// Mirrors the backend `CategoryResponse` shape used by `GET /Category`.
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.isActive,
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
