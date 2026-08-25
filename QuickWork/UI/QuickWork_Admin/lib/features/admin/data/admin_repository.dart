import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../auth/models/role_model.dart';
import '../models/admin_job_application_model.dart';
import '../models/admin_job_posting_model.dart';
import '../models/admin_review_model.dart';
import '../models/city_option.dart';
import '../models/gender_option.dart';
import '../models/notification_model.dart';
import '../models/notification_payload.dart';
import '../models/user_response_model.dart' show AdminUserModel;
import '../models/user_activation_payload.dart';
import '../models/user_update_payload.dart';
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

  /// Fetches a single user by id via `GET /Users/{id}`.
  Future<AdminUserModel> fetchUserById(int id) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/Users/$id',
      );
      return AdminUserModel.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Updates a user's profile (and roles / active flag) via `PUT /Users/{id}`.
  Future<AdminUserModel> updateUser({
    required int userId,
    required UserUpdatePayload payload,
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
  // Lookups (genders / cities / roles) for the profile edit form
  // ---------------------------------------------------------------------------

  /// Fetches the gender options.
  Future<List<GenderOption>> fetchGenders() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/Gender',
        queryParameters: const {'PageSize': 100, 'IncludeTotalCount': true},
      );
      final items = response.data?['items'] as List<dynamic>? ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(GenderOption.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Fetches the city options.
  Future<List<CityOption>> fetchCities() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/City',
        queryParameters: const {'PageSize': 200, 'IncludeTotalCount': true},
      );
      final items = response.data?['items'] as List<dynamic>? ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(CityOption.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Fetches the available roles (for assigning/removing roles).
  Future<List<RoleModel>> fetchRoles() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/Role',
        queryParameters: const {'PageSize': 100, 'IncludeTotalCount': true},
      );
      final items = response.data?['items'] as List<dynamic>? ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(RoleModel.fromJson)
          .toList();
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

  /// Removes (hard-deletes) a job posting via `DELETE /JobPostings/{id}`.
  ///
  /// The backend cascades to the job's applications, messages, reviews and
  /// payments (their FK relationships use `DeleteBehavior.Cascade`).
  Future<void> deleteJob(int id) async {
    try {
      await _apiClient.dio.delete<Map<String, dynamic>>('/JobPostings/$id');
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
  // Job applications (worker requests — oversight / moderation)
  // ---------------------------------------------------------------------------

  /// Fetches job applications (worker requests) matching [filters].
  /// Supports pagination and status filtering (`Pending`, `Accepted`, ...).
  Future<List<AdminJobApplicationModel>> fetchJobApplications({
    int? jobPostingId,
    int? applicantUserId,
    String? status,
    int? page,
    int? pageSize,
  }) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/JobApplications',
        queryParameters: {
          if (jobPostingId != null) 'JobPostingId': jobPostingId,
          if (applicantUserId != null) 'ApplicantUserId': applicantUserId,
          if (status != null && status.isNotEmpty) 'Status': status,
          if (page != null) 'Page': page,
          'PageSize': pageSize ?? 200,
          'IncludeTotalCount': true,
        },
      );

      final items = response.data?['items'] as List<dynamic>? ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(AdminJobApplicationModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Removes (hard-deletes) a job application / request via
  /// `DELETE /JobApplications/{id}`.
  Future<void> deleteJobApplication(int id) async {
    try {
      await _apiClient.dio.delete<Map<String, dynamic>>('/JobApplications/$id');
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

  // ---------------------------------------------------------------------------
  // Notifications (announcements)
  // ---------------------------------------------------------------------------

  /// Fetches the most recent notifications (the service orders by createdAt
  /// descending). [pageSize] is used to limit history to the latest N.
  Future<List<AdminNotificationModel>> fetchNotifications({
    int? userId,
    int? page,
    int? pageSize,
  }) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/Notifications',
        queryParameters: {
          if (userId != null) 'UserId': userId,
          if (page != null) 'Page': page,
          'PageSize': pageSize ?? 10,
          'IncludeTotalCount': true,
        },
      );

      final items = response.data?['items'] as List<dynamic>? ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(AdminNotificationModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Creates a notification for a single [payload.userId] via
  /// `POST /Notifications`. Returns the created notification.
  Future<AdminNotificationModel> createNotification(
    NotificationPayload payload,
  ) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/Notifications',
        data: payload.toJson(),
      );
      return AdminNotificationModel.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Removes (hard-deletes) a notification via `DELETE /Notifications/{id}`.
  Future<void> deleteNotification(int id) async {
    try {
      await _apiClient.dio.delete<Map<String, dynamic>>('/Notifications/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}


