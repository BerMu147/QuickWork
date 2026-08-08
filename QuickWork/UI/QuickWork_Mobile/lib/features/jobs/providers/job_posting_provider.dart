import 'package:flutter/foundation.dart';

import '../../../core/api/api_exceptions.dart';
import '../data/job_posting_repository.dart';
import '../models/job_posting_model.dart';

/// Holds the list of job postings and manages their loading state.
class JobPostingProvider extends ChangeNotifier {
  JobPostingProvider({JobPostingRepository? repository})
      : _repository = repository ?? JobPostingRepository();

  final JobPostingRepository _repository;

  List<JobPostingModel> _jobPostings = [];
  bool _isLoading = false;
  String? _error;

  List<JobPostingModel> get jobPostings => _jobPostings;
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  JobPostingModel? byId(int id) {
    for (final jp in _jobPostings) {
      if (jp.id == id) return jp;
    }
    return null;
  }
}
