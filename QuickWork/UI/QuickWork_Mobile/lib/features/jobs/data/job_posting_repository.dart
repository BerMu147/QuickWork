import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../models/job_application_model.dart';
import '../models/job_application_request.dart';
import '../models/job_posting_model.dart';

/// Optional query filters for the job postings list.
class JobPostingQuery {
  const JobPostingQuery({
    this.title,
    this.categoryId,
    this.cityId,
    this.status = 'Open',
    this.page,
    this.pageSize,
  });

  final String? title;
  final int? categoryId;
  final int? cityId;
  final String? status;
  final int? page;
  final int? pageSize;

  Map<String, dynamic> toQueryParameters() {
    return {
      if (title != null && title!.isNotEmpty) 'Title': title,
      if (categoryId != null) 'CategoryId': categoryId,
      if (cityId != null) 'CityId': cityId,
      if (status != null && status!.isNotEmpty) 'Status': status,
      if (page != null) 'Page': page,
      if (pageSize != null) 'PageSize': pageSize,
    };
  }
}

/// Fetches job postings from the backend.
class JobPostingRepository {
  JobPostingRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// Returns the list of job postings matching [query].
  Future<List<JobPostingModel>> fetchJobPostings(
      [JobPostingQuery? query]) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/JobPostings',
        queryParameters: (query ?? const JobPostingQuery()).toQueryParameters(),
      );

      final items = response.data?['items'] as List<dynamic>? ?? [];
      return items
          .map((e) => JobPostingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Returns a single job posting by id.
  Future<JobPostingModel> fetchJobPosting(int id) async {
    try {
      final response =
          await _apiClient.dio.get<Map<String, dynamic>>('/JobPostings/$id');
      return JobPostingModel.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Submits a job application on behalf of [applicantUserId].
  Future<JobApplicationModel> applyToJob({
    required int jobPostingId,
    required int applicantUserId,
    String? message,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/JobApplications',
        queryParameters: {'applicantUserId': applicantUserId},
        data: JobApplicationRequest(
          jobPostingId: jobPostingId,
          message: message,
        ).toJson(),
      );

      return JobApplicationModel.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Returns the applications submitted by [applicantUserId].
  Future<List<JobApplicationModel>> fetchApplicationsForUser(int applicantUserId) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/JobApplications',
        queryParameters: {'ApplicantUserId': applicantUserId},
      );

      final items = response.data?['items'] as List<dynamic>? ?? [];
      return items
          .map((e) => JobApplicationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

