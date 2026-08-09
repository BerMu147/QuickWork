import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../models/user_model.dart';
import '../models/user_update_request.dart';

/// Handles user-profile API calls against the backend.
class UserRepository {
  UserRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// Updates a user's profile via `PUT /Users/{id}` and returns the updated
  /// user. Throws an [ApiException] on failure.
  Future<UserModel> updateUser({
    required int id,
    required UserUpdateRequest request,
  }) async {
    try {
      final response = await _apiClient.dio.put<Map<String, dynamic>>(
        '/Users/$id',
        data: request.toJson(),
      );

      return UserModel.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Fetches a single user's profile via `GET /Users/{id}`. Throws an
  /// [ApiException] on failure.
  Future<UserModel> fetchUser(int id) async {
    try {
      final response =
          await _apiClient.dio.get<Map<String, dynamic>>('/Users/$id');
      return UserModel.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
