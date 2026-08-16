import 'package:flutter/foundation.dart';

import '../../../core/api/api_exceptions.dart';
import '../data/review_repository.dart';
import '../models/review_model.dart';

/// Holds the reviews received by a user plus their average rating, and manages
/// submitting a new review.
class ReviewProvider extends ChangeNotifier {
  ReviewProvider({ReviewRepository? repository})
      : _repository = repository ?? ReviewRepository();

  final ReviewRepository _repository;

  List<ReviewModel> _reviews = [];
  double _averageRating = 0;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  String? _submitError;

  List<ReviewModel> get reviews => _reviews;
  double get averageRating => _averageRating;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  String? get submitError => _submitError;

  /// Whether a review from [reviewerUserId] for [jobPostingId] is already
  /// present in the loaded list (used to hide / disable duplicate review
  /// actions).
  bool hasReviewed({required int reviewerUserId, required int jobPostingId}) {
    return _reviews.any(
      (r) => r.reviewerUserId == reviewerUserId && r.jobPostingId == jobPostingId,
    );
  }

  /// Loads the reviews received by [reviewedUserId] plus their average rating.
  Future<void> loadForUser(int reviewedUserId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.fetchReviewsForUser(reviewedUserId),
        _repository.fetchAverageRating(reviewedUserId),
      ]);
      _reviews = results[0] as List<ReviewModel>;
      _averageRating = results[1] as double;
    } on ApiException {
      // Keep previous values on failure; not critical.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Submits a review. Returns true on success, false on failure (error stored
  /// in [submitError]).
  Future<bool> submitReview({
    required int reviewerUserId,
    required int reviewedUserId,
    required int jobPostingId,
    required int rating,
    String? comment,
  }) async {
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      final created = await _repository.createReview(
        reviewerUserId: reviewerUserId,
        reviewedUserId: reviewedUserId,
        jobPostingId: jobPostingId,
        rating: rating,
        comment: comment,
      );
      // Prepend the new review and repull the average so both reflect it.
      _reviews = [created, ..._reviews];
      _averageRating = await _repository.fetchAverageRating(reviewedUserId);
      return true;
    } on ApiException catch (e) {
      _submitError = e.message;
      return false;
    } catch (_) {
      _submitError = 'Unable to submit the review. Please try again.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Clears stale data so a subsequent [loadForUser] starts fresh (useful when
  /// switching to a different user on the same provider).
  void clear() {
    _reviews = [];
    _averageRating = 0;
    _error = null;
    _submitError = null;
    notifyListeners();
  }
}
