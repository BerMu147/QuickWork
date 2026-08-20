import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../models/admin_job_posting_model.dart';
import '../models/admin_review_model.dart';
import '../models/user_response_model.dart' show AdminUserModel;
import '../models/user_activation_payload.dart';
import '../models/category_model.dart';

/// Handles all data used by the administrator console.
///
/// These are plain reads/aggregations over the platform's existing REST
/// endpoints (`/Users`, `/JobPostings`, `/Reviews`, `/Category`, ...).
class AdminRepository {
  AdminRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  // ---------------------------------------------------------------------------
  // Users
  // ---------------------------------------------------------------------------

  /// Fetches users matching [filters]. Supports pagination.
  Future<List<AdminUserModel>> fetchUsers({
    String? username,
    String? email,
    int? roleId,
    int? page,
    int? pageSize,
  }) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/Users',
        queryParameters: {
          if (username != null && username.isNotEmpty) 'Username': username,
          if (email != null && email.isNotEmpty) 'Email': email,
          if (roleId != null) 'RoleId': roleId,
          if (page != null) 'Page': page,
          'PageSize': pageSize ?? 100,
          'IncludeTotalCount': true,
        },
      );

      final items = response.data?['items'] as List<dynamic>? ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(AdminUserModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Toggles a user's active flag via `PUT /Users/{id}`.
  Future<AdminUserModel> setActive({
    required int userId,
    required UserActivationPayload payload,
  }) async {
    try {
      final response = await _apiClient.dio.put<Map<String, dynamic>>(
        '/Users/$userId',
        data: payload.toJson(),
      );
      return AdminUserModel.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Job postings (moderation)
  // ---------------------------------------------------------------------------

  /// Fetches job postings matching [filters]. Supports pagination.
  Future<List<AdminJobPostingModel>> fetchJobPostings({
    String? status,
    int? categoryId,
    String? title,
    int? page,
    int? pageSize,
  }) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/JobPostings',
        queryParameters: {
          if (status != null && status.isNotEmpty) 'Status': status,
          if (categoryId != null) 'CategoryId': categoryId,
          if (title != null && title.isNotEmpty) 'Title': title,
          if (page != null) 'Page': page,
          'PageSize': pageSize ?? 100,
          'IncludeTotalCount': true,
        },
      );

      final items = response.data?['items'] as List<dynamic>? ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(AdminJobPostingModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Reviews (moderation)
  // ---------------------------------------------------------------------------

  /// Fetches reviews matching [filters]. Supports pagination.
  Future<List<AdminReviewModel>> fetchReviews({
    int? reviewedUserId,
    int? minRating,
    int? maxRating,
    int? page,
    int? pageSize,
  }) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/Reviews',
        queryParameters: {
          if (reviewedUserId != null) 'ReviewedUserId': reviewedUserId,
          if (minRating != null) 'MinRating': minRating,
          if (maxRating != null) 'MaxRating': maxRating,
          if (page != null) 'Page': page,
          'PageSize': pageSize ?? 100,
          'IncludeTotalCount': true,
        },
      );

      final items = response.data?['items'] as List<dynamic>? ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(AdminReviewModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Removes (hard-deletes) a review via `DELETE /Reviews/{id}`.
  Future<void> deleteReview(int id) async {
    try {
      await _apiClient.dio.delete<Map<String, dynamic>>('/Reviews/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Categories (job-offer / job-demand overview)
  // ---------------------------------------------------------------------------

  /// Fetches all active job categories.
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/Category',
        queryParameters: const {'PageSize': 100, 'IncludeTotalCount': true},
      );

      final items = response.data?['items'] as List<dynamic>? ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(CategoryModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

