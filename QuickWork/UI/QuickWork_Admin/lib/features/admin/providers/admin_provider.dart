import 'package:flutter/foundation.dart';

import '../../auth/models/role_model.dart';
import '../data/admin_repository.dart';
import '../models/admin_job_posting_model.dart';
import '../models/admin_review_model.dart';
import '../models/category_model.dart';
import '../models/city_option.dart';
import '../models/gender_option.dart';
import '../models/user_response_model.dart';
import '../models/user_activation_payload.dart';
import '../models/user_update_payload.dart';

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

  // ---- User profile detail --------------------------------------------------
  AdminUserModel? _userDetail;
  bool _isLoadingUserDetail = false;
  String? _userDetailError;
  bool _isSavingUser = false;
  String? _userSaveError;

  // ---- Lookups (genders / cities / roles) ----------------------------------
  List<GenderOption> _genders = [];
  List<CityOption> _cities = [];
  List<RoleModel> _allRoles = [];
  bool _isLoadingLookups = false;
  String? _lookupsError;

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

  AdminUserModel? get userDetail => _userDetail;
  bool get isLoadingUserDetail => _isLoadingUserDetail;
  String? get userDetailError => _userDetailError;
  bool get isSavingUser => _isSavingUser;
  String? get userSaveError => _userSaveError;

  List<GenderOption> get genders => _genders;
  List<CityOption> get cities => _cities;
  List<RoleModel> get allRoles => _allRoles;
  bool get isLoadingLookups => _isLoadingLookups;
  String? get lookupsError => _lookupsError;

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

  /// Loads a single user's full profile for the detail/edit view.
  Future<void> loadUserDetail(int userId) async {
    _isLoadingUserDetail = true;
    _userDetailError = null;
    notifyListeners();

    try {
      _userDetail = await _repository.fetchUserById(userId);
      _isLoadingUserDetail = false;
    } catch (e) {
      _isLoadingUserDetail = false;
      _userDetailError = e.toString();
    }
    notifyListeners();
  }

  /// Loads gender / city / role options for the profile edit form.
  Future<void> loadLookups() async {
    _isLoadingLookups = true;
    _lookupsError = null;
    notifyListeners();

    try {
      final results = await Future.wait<Object>([
        _repository.fetchGenders(),
        _repository.fetchCities(),
        _repository.fetchRoles(),
      ]);
      _genders = results[0] as List<GenderOption>;
      _cities = results[1] as List<CityOption>;
      _allRoles = results[2] as List<RoleModel>;
      _isLoadingLookups = false;
    } catch (e) {
      _isLoadingLookups = false;
      _lookupsError = e.toString();
    }
    notifyListeners();
  }

  /// Persists an admin edit to a user's profile, roles and active flag.
  ///
  /// Also refreshes the user-detail state and the users directory so the
  /// console reflects the change everywhere.
  Future<bool> updateUser({
    required int userId,
    required UserUpdatePayload payload,
  }) async {
    _isSavingUser = true;
    _userSaveError = null;
    notifyListeners();

    try {
      final updated =
          await _repository.updateUser(userId: userId, payload: payload);
      _userDetail = updated;
      _users = _users.map((u) => u.id == updated.id ? updated : u).toList();
      _isSavingUser = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSavingUser = false;
      _userSaveError = e.toString();
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
