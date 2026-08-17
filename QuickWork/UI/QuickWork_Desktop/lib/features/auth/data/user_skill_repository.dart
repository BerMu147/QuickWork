import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../models/user_skill_model.dart';

/// Handles the current user's custom skills API calls against the backend.
class UserSkillRepository {
  UserSkillRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// Returns the custom skills for [userId] via `GET /UserSkills?UserId=...`.
  Future<List<UserSkillModel>> fetchSkillsForUser(int userId) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/UserSkills',
        queryParameters: {
          'UserId': userId,
          'PageSize': 100,
          'IncludeTotalCount': true,
        },
      );

      final items = response.data?['items'] as List<dynamic>? ?? [];
      return items
          .map((e) => UserSkillModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Adds a new skill for [userId] via `POST /UserSkills?userId=...`.
  /// Returns the created skill.
  Future<UserSkillModel> addSkill({
    required int userId,
    required String skillName,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/UserSkills',
        queryParameters: {'userId': userId},
        data: {'skillName': skillName},
      );
      return UserSkillModel.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Removes a skill via `DELETE /UserSkills/{id}?userId=...`.
  Future<void> deleteSkill({
    required int id,
    required int userId,
  }) async {
    try {
      await _apiClient.dio.delete<void>(
        '/UserSkills/$id',
        queryParameters: {'userId': userId},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
