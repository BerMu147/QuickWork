import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../models/city_model.dart';
import '../models/gender_model.dart';

/// Fetches reference/lookup data (genders, cities) from the backend.
class LookupRepository {
  LookupRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// Returns the list of genders.
  Future<List<GenderModel>> fetchGenders() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>('/Gender');
      final items = response.data?['items'] as List<dynamic>? ?? [];
      return items
          .map((e) => GenderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Returns the list of cities.
  Future<List<CityModel>> fetchCities() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>('/City');
      final items = response.data?['items'] as List<dynamic>? ?? [];
      return items
          .map((e) => CityModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
