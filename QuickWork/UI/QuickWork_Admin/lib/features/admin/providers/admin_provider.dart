import 'package:flutter/foundation.dart';

import '../data/admin_repository.dart';
import '../models/admin_job_posting_model.dart';
import '../models/admin_review_model.dart';
import '../models/category_model.dart';
import '../models/user_response_model.dart';
import '../models/user_activation_payload.dart';

/// Aggregate analytics shown on the dashboard KPI cards.
class DashboardSummary {
  const DashboardSummary({
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.totalJobs = 0,
    this.openJobs = 0,
    this.inProgressJobs = 0,
    this.completedJobs = 0,
    this.cancelledJobs = 0,
    this.totalReviews = 0,
    this.totalCategories = 0,
  });

  final int totalUsers;
  final int activeUsers;
  final int totalJobs;
  final int openJobs;
  final int inProgressJobs;
  final int completedJobs;
  final int cancelledJobs;
  final int totalReviews;
  final int totalCategories;
}

/// A computed category row for the job-offer / job-demand overview.
class CategoryOverviewItem {
  const CategoryOverviewItem({
    required this.category,
    required this.jobCount,
  });

  final CategoryModel category;
  final int jobCount;
}

/// Holds administrator console state: analytics, user directory, job
/// moderation and review moderation data.
class AdminProvider extends ChangeNotifier {
  AdminProvider({AdminRepository? repository})
      : _repository = repository ?? AdminRepository();

  final AdminRepository _repository;

  // ---- Dashboard ------------------------------------------------------------
  DashboardSummary _summary = const DashboardSummary();
  List<CategoryOverviewItem> _categoryOverview = [];
  bool _isLoadingDashboard = false;
  String? _dashboardError;

  // ---- Users ----------------------------------------------------------------
  List<AdminUserModel> _users = [];
  bool _isLoadingUsers = false;
  String? _usersError;

  // ---- Jobs (moderation) ----------------------------------------------------
  List<AdminJobPostingModel> _jobs = [];
  bool _isLoadingJobs = false;
  String? _jobsError;

  // ---- Reviews (moderation) -------------------------------------------------
  List<AdminReviewModel> _reviews = [];
  bool _isLoadingReviews = false;
  String? _reviewsError;
  bool _isDeletingReview = false;

  // ---- Getters --------------------------------------------------------------
  DashboardSummary get summary => _summary;
  List<CategoryOverviewItem> get categoryOverview => _categoryOverview;
  bool get isLoadingDashboard => _isLoadingDashboard;
  String? get dashboardError => _dashboardError;

  List<AdminUserModel> get users => _users;
  bool get isLoadingUsers => _isLoadingUsers;
  String? get usersError => _usersError;

  List<AdminJobPostingModel> get jobs => _jobs;
  bool get isLoadingJobs => _isLoadingJobs;
  String? get jobsError => _jobsError;

  List<AdminReviewModel> get reviews => _reviews;
  bool get isLoadingReviews => _isLoadingReviews;
  String? get reviewsError => _reviewsError;
  bool get isDeletingReview => _isDeletingReview;

  // ---------------------------------------------------------------------------
  // Dashboard / analytics
  // ---------------------------------------------------------------------------

  /// Loads the dashboard summary: user/job/review/category counts and the
  /// job-offer vs job-demand breakdown by category.
  Future<void> loadDashboard() async {
    _isLoadingDashboard = true;
    _dashboardError = null;
    notifyListeners();

    try {
      final results = await Future.wait<Object>([
        _repository.fetchUsers(pageSize: 500),
        _repository.fetchJobPostings(pageSize: 500),
        _repository.fetchReviews(pageSize: 500),
        _repository.fetchCategories(),
      ]);

      final allUsers = (results[0] as List<AdminUserModel>);
      final allJobs = (results[1] as List<AdminJobPostingModel>);
      final allReviews = (results[2] as List<AdminReviewModel>);
      final categories = (results[3] as List<CategoryModel>);

      // The dashboard aggregates are computed client-side over the paginated
      // collections the backend exposes (there is no dedicated analytics
      // endpoint yet). A generous page size gives representative totals.
      final activeUsers = allUsers.where((u) => u.isActive).length;

      final openJobs = allJobs.where((j) => j.status.toLowerCase() == 'open').length;
      final inProgressJobs =
          allJobs.where((j) => j.status.toLowerCase() == 'inprogress').length;
      final completedJobs =
          allJobs.where((j) => j.status.toLowerCase() == 'completed').length;
      final cancelledJobs =
          allJobs.where((j) => j.status.toLowerCase() == 'cancelled').length;

      _summary = DashboardSummary(
        totalUsers: allUsers.length,
        activeUsers: activeUsers,
        totalJobs: allJobs.length,
        openJobs: openJobs,
        inProgressJobs: inProgressJobs,
        completedJobs: completedJobs,
        cancelledJobs: cancelledJobs,
        totalReviews: allReviews.length,
        totalCategories: categories.length,
      );

      // Job-offer / job-demand overview by category.
      _categoryOverview = categories
          .map((c) => CategoryOverviewItem(
                category: c,
                jobCount: allJobs.where((j) => j.categoryId == c.id).length,
              ))
          .where((item) => item.jobCount > 0)
          .toList();
      _categoryOverview.sort((a, b) => b.jobCount.compareTo(a.jobCount));

      _isLoadingDashboard = false;
    } catch (e) {
      _isLoadingDashboard = false;
      _dashboardError = e.toString();
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Users
  // ---------------------------------------------------------------------------

  /// Loads the user directory with optional [username] filter.
  Future<void> loadUsers({String? username}) async {
    _isLoadingUsers = true;
    _usersError = null;
    notifyListeners();

    try {
      final result =
          await _repository.fetchUsers(username: username, pageSize: 200);
      _users = result;
      _isLoadingUsers = false;
    } catch (e) {
      _isLoadingUsers = false;
      _usersError = e.toString();
    }
    notifyListeners();
  }

  /// Activates or deactivates [user], keeping all other data (and roles)
  /// intact. Refreshes the local list on success.
  Future<bool> toggleUserActive(AdminUserModel user) async {
    try {
      final updated = await _repository.setActive(
        userId: user.id,
        payload: UserActivationPayload.fromUser(
          user,
          newIsActive: !user.isActive,
        ),
      );
      _users = _users.map((u) => u.id == updated.id ? updated : u).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _usersError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Jobs (moderation)
  // ---------------------------------------------------------------------------

  /// Loads job postings for moderation with optional [status] filter.
  Future<void> loadJobs({String? status}) async {
    _isLoadingJobs = true;
    _jobsError = null;
    notifyListeners();

    try {
      final result =
          await _repository.fetchJobPostings(status: status, pageSize: 200);
      _jobs = result;
      _isLoadingJobs = false;
    } catch (e) {
      _isLoadingJobs = false;
      _jobsError = e.toString();
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Reviews (moderation)
  // ---------------------------------------------------------------------------

  /// Loads reviews for moderation.
  Future<void> loadReviews() async {
    _isLoadingReviews = true;
    _reviewsError = null;
    notifyListeners();

    try {
      final result = await _repository.fetchReviews(pageSize: 200);
      _reviews = result;
      _isLoadingReviews = false;
    } catch (e) {
      _isLoadingReviews = false;
      _reviewsError = e.toString();
    }
    notifyListeners();
  }

  /// Removes an abusive review and refreshes the list.
  Future<bool> removeReview(AdminReviewModel review) async {
    _isDeletingReview = true;
    _reviewsError = null;
    notifyListeners();

    try {
      await _repository.deleteReview(review.id);
      _reviews = _reviews.where((r) => r.id != review.id).toList();
      _isDeletingReview = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isDeletingReview = false;
      _reviewsError = e.toString();
      notifyListeners();
      return false;
    }
  }
}
