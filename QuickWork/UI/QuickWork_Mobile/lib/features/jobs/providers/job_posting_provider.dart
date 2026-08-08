import 'package:flutter/foundation.dart';

import '../../../core/api/api_exceptions.dart';
import '../data/job_posting_repository.dart';
import '../models/job_application_model.dart';
import '../models/job_posting_model.dart';

/// Holds the list of job postings and manages their loading/application state.
class JobPostingProvider extends ChangeNotifier {
  JobPostingProvider({JobPostingRepository? repository})
      : _repository = repository ?? JobPostingRepository();

  final JobPostingRepository _repository;

  List<JobPostingModel> _jobPostings = [];
  List<JobApplicationModel> _myApplications = [];
  bool _isLoading = false;
  bool _isApplying = false;
  String? _error;
  String? _applicationError;

  List<JobPostingModel> get jobPostings => _jobPostings;
  List<JobApplicationModel> get myApplications => _myApplications;
  bool get isLoading => _isLoading;
  bool get isApplying => _isApplying;
  String? get error => _error;
  String? get applicationError => _applicationError;

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

  JobPostingModel? byId(int id) {
    for (final jp in _jobPostings) {
      if (jp.id == id) return jp;
    }
    return null;
  }
}

