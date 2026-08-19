import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

/// Handles authentication-related API calls against the backend.
class AuthRepository {
  AuthRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// Calls `POST /Users/authenticate` and returns the [LoginResponse].
  ///
  /// Throws an [ApiException] on failure.
  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/Users/authenticate',
        data: LoginRequest(username: username, password: password).toJson(),
      );

      final data = response.data;
      if (data == null) {
        throw const ApiException(message: 'Unexpected empty response from server.');
      }

      return LoginResponse.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Unable to log in. $e');
    }
  }
}
