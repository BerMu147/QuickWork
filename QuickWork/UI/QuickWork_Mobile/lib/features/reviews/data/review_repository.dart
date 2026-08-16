import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../models/review_model.dart';

/// Handles review API calls against the backend.
class ReviewRepository {
  ReviewRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// Returns the reviews received by [userId] (as the reviewed party) via
  /// `GET /Reviews?ReviewedUserId=...`.
  Future<List<ReviewModel>> fetchReviewsForUser(int userId) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/Reviews',
        queryParameters: {
          'ReviewedUserId': userId,
          'IncludeTotalCount': true,
          'PageSize': 100,
        },
      );

      final items = response.data?['items'] as List<dynamic>? ?? [];
      return items
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Returns the average active-rating for [userId] via
  /// `GET /Reviews/average-rating/{userId}`. Returns 0 when there are no
  /// active reviews.
  Future<double> fetchAverageRating(int userId) async {
    try {
      final response =
          await _apiClient.dio.get<num>('/Reviews/average-rating/$userId');
      final value = response.data;
      return value?.toDouble() ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Creates a review by [reviewerUserId] about [reviewedUserId] for a job.
  /// Returns the created review.
  Future<ReviewModel> createReview({
    required int reviewerUserId,
    required int reviewedUserId,
    required int jobPostingId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/Reviews',
        queryParameters: {'reviewerUserId': reviewerUserId},
        data: {
          'jobPostingId': jobPostingId,
          'reviewedUserId': reviewedUserId,
          'rating': rating,
          'comment': comment,
          'isActive': true,
        },
      );
      return ReviewModel.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
