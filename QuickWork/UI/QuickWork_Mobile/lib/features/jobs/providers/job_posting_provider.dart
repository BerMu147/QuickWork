import 'package:flutter/foundation.dart';

import '../../../core/api/api_exceptions.dart';
import '../data/job_posting_repository.dart';
import '../models/category_model.dart';
import '../models/job_application_model.dart';
import '../models/job_posting_model.dart';
import '../models/job_posting_upsert_request.dart';

/// Holds the list of job post  ings and manages their loading/application state.
class JobPostingProvider extends ChangeNotifier {
  JobPostingProvider({JobPostingRepository? repository})
      : _repository = repository ?? JobPostingRepository();

  final JobPostingRepository _repository;

  List<JobPostingModel> _jobPostings = [];
  List<JobPostingModel> _myJobPostings = [];
  List<JobApplicationModel> _myApplications = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  bool _isLoadingMyJobs = false;
  bool _isApplying = false;
  bool _isPublishing = false;
  String? _error;
  String? _applicationError;
  String? _publishError;

  List<JobPostingModel> get jobPostings => _jobPostings;
  List<JobPostingModel> get myJobPostings => _myJobPostings;
  List<JobApplicationModel> get myApplications => _myApplications;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isLoadingMyJobs => _isLoadingMyJobs;
  bool get isApplying => _isApplying;
  bool get isPublishing => _isPublishing;
  String? get error => _error;
  String? get applicationError => _applicationError;
  String? get publishError => _publishError;

  /// Loads the job postings (optionally filtered). Returns true on success.
  Future<bool> loadJobPostings({JobPostingQuery? query}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _jobPostings = await _repository.fetchJobPostings(query);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Unable to load job postings. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Submits an application for [jobPostingId] on behalf of [applicantUserId].
  ///
  /// Returns true on success, false on failure (error stored in
  /// [applicationError]).
  Future<bool> applyToJob({
    required int jobPostingId,
    required int applicantUserId,
    String? message,
  }) async {
    _isApplying = true;
    _applicationError = null;
    notifyListeners();

    try {
      final app = await _repository.applyToJob(
        jobPostingId: jobPostingId,
        applicantUserId: applicantUserId,
        message: message,
      );
      // Add to the local "my applications" list for future use.
      _myApplications = [..._myApplications, app];
      return true;
    } on ApiException catch (e) {
      _applicationError = e.message;
      return false;
    } catch (_) {
      _applicationError = 'Unable to submit your application. Please try again.';
      return false;
    } finally {
      _isApplying = false;
      notifyListeners();
    }
  }

  /// Loads the applications submitted by [applicantUserId].
  Future<void> loadMyApplications(int applicantUserId) async {
    try {
      _myApplications =
          await _repository.fetchApplicationsForUser(applicantUserId);
      notifyListeners();
    } on ApiException {
      // Keep existing list; not critical.
    }
  }

  /// Returns the current user's application to [jobPostingId], or null if they
  /// have not applied. Fetches (and caches) the user's applications when needed.
  Future<JobApplicationModel?> applicationForJob({
    required int jobPostingId,
    required int applicantUserId,
  }) async {
    if (_myApplications.isEmpty && applicantUserId > 0) {
      _myApplications =
          await _repository.fetchApplicationsForUser(applicantUserId);
    }
    for (final a in _myApplications) {
      if (a.jobPostingId == jobPostingId) return a;
    }
    return null;
  }

  /// Whether [jobPostingId] is one of the current user's own postings.
  bool ownsJob(int jobPostingId) =>
      _myJobPostings.any((j) => j.id == jobPostingId);

  /// Loads the jobs the user has published plus their applications.
  ///
  /// Used to populate the "My Jobs" tab.
  Future<void> loadMyJobs(int userId) async {
    _isLoadingMyJobs = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.fetchJobsForUser(userId),
        _repository.fetchApplicationsForUser(userId),
      ]);
      _myJobPostings = results[0] as List<JobPostingModel>;
      _myApplications = results[1] as List<JobApplicationModel>;
    } on ApiException {
      // Leave as-is.
    } finally {
      _isLoadingMyJobs = false;
      notifyListeners();
    }
  }

  /// Updates the status of one of the user's received applications
  /// (publisher Accept/Reject) and refreshes the local reference data.
  ///
  /// Returns true on success, false on failure (error in [applicationError]).
  Future<bool> updateApplicationStatus({
    required int applicationId,
    required int jobPostingId,
    required String status,
  }) async {
    _applicationError = null;
    notifyListeners();

    try {
      final updated = await _repository.updateApplicationStatus(
        applicationId: applicationId,
        jobPostingId: jobPostingId,
        status: status,
      );

      // Update the matching entry in the local applications list, if present.
      final index = _myApplications.indexWhere((a) => a.id == updated.id);
      if (index != -1) {
        _myApplications = [..._myApplications]..[index] = updated;
      }
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _applicationError = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _applicationError = 'Unable to update the application. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Returns the applications received for one of the user's own job postings.
  Future<List<JobApplicationModel>> applicationsForJob(int jobPostingId) =>
      _repository.fetchApplicationsForJob(jobPostingId);

  JobPostingModel? byId(int id) {
    for (final jp in _jobPostings) {
      if (jp.id == id) return jp;
    }
    return null;
  }

  /// Loads the available job categories (requires authentication).
  Future<List<CategoryModel>> loadCategories() async {
    try {
      _categories = await _repository.fetchCategories();
      notifyListeners();
    } on ApiException {
      // Leave categories empty on failure.
    }
    return _categories;
  }

  /// Publishes a new job posting on behalf of [postedByUserId].
  ///
  /// Returns true on success, false on failure (error in [publishError]).
  Future<bool> publishJob({
    required JobPostingUpsertRequest request,
    required int postedByUserId,
  }) async {
    _isPublishing = true;
    _publishError = null;
    notifyListeners();

    try {
      final created = await _repository.createJobPosting(
        request: request,
        postedByUserId: postedByUserId,
      );
      // Prepend to the front of the local list so it shows immediately.
      _jobPostings = [created, ..._jobPostings];
      return true;
    } on ApiException catch (e) {
      _publishError = e.message;
      return false;
    } catch (_) {
      _publishError = 'Unable to publish the job. Please try again.';
      return false;
    } finally {
      _isPublishing = false;
      notifyListeners();
    }
  }
}

