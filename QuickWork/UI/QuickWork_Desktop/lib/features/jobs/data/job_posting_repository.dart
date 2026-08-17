import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../models/category_model.dart';
import '../models/job_application_model.dart';
import '../models/job_application_request.dart';
import '../models/job_posting_model.dart';
import '../models/job_posting_upsert_request.dart';

/// Optional query filters for the job postings list.
class JobPostingQuery {
  const JobPostingQuery({
    this.title,
    this.categoryId,
    this.cityId,
    this.postedByUserId,
    this.status = 'Open',
    this.page,
    this.pageSize,
  });

  final String? title;
  final int? categoryId;
  final int? cityId;
  final int? postedByUserId;
  final String? status;
  final int? page;
  final int? pageSize;

  Map<String, dynamic> toQueryParameters() {
    return {
      if (title != null && title!.isNotEmpty) 'Title': title,
      if (categoryId != null) 'CategoryId': categoryId,
      if (cityId != null) 'CityId': cityId,
      if (postedByUserId != null) 'PostedByUserId': postedByUserId,
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

  /// Returns the applications received for a specific [jobPostingId].
  Future<List<JobApplicationModel>> fetchApplicationsForJob(
      int jobPostingId) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/JobApplications',
        queryParameters: {'JobPostingId': jobPostingId},
      );

      final items = response.data?['items'] as List<dynamic>? ?? [];
      return items
          .map((e) => JobApplicationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Returns the job postings published by [userId].
  ///
  /// [fetchOwn] fetches the detail of a posted job; [withApplications] loads
  /// the applications each job received (used for the "My Jobs" tab).
  Future<List<JobPostingModel>> fetchJobsForUser(int userId) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/JobPostings',
        queryParameters: {'PostedByUserId': userId},
      );

      final items = response.data?['items'] as List<dynamic>? ?? [];
      return items
          .map((e) => JobPostingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Returns the available job categories (requires authentication).
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

  /// Creates a new job posting on behalf of [postedByUserId]. Returns the
  /// created posting.
  Future<JobPostingModel> createJobPosting({
    required JobPostingUpsertRequest request,
    required int postedByUserId,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/JobPostings',
        queryParameters: {'postedByUserId': postedByUserId},
        data: request.toJson(),
      );

      return JobPostingModel.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Transitions a job's status (publisher "mark in progress" / "mark
  /// complete") via `PUT /JobPostings/{id}/status`. Returns the updated job.
  Future<JobPostingModel> updateJobStatus({
    required int jobPostingId,
    required String status,
    required int postedByUserId,
  }) async {
    try {
      final response = await _apiClient.dio.put<Map<String, dynamic>>(
        '/JobPostings/$jobPostingId/status',
        queryParameters: {
          'postedByUserId': postedByUserId,
          'status': status,
        },
      );
      return JobPostingModel.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Updates the status of a job application (publisher Accept/Reject) via
  /// `PUT /JobApplications/{id}`. Returns the updated application.
  Future<JobApplicationModel> updateApplicationStatus({
    required int applicationId,
    required int jobPostingId,
    required String status,
    String? message,
  }) async {
    try {
      final response = await _apiClient.dio.put<Map<String, dynamic>>(
        '/JobApplications/$applicationId',
        data: JobApplicationRequest(
          jobPostingId: jobPostingId,
          status: status,
          message: message,
        ).toJson(),
      );
      return JobApplicationModel.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
