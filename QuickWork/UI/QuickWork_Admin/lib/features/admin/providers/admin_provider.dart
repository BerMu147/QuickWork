import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../auth/models/role_model.dart';
import '../data/admin_repository.dart';
import '../models/admin_job_application_model.dart';
import '../models/admin_job_posting_model.dart';
import '../models/admin_review_model.dart';
import '../models/category_model.dart';
import '../models/city_option.dart';
import '../models/gender_option.dart';
import '../models/market_analytics_model.dart';
import '../models/notification_model.dart';
import '../models/notification_payload.dart';
import '../models/report_models.dart';
import '../models/user_response_model.dart';
import '../models/user_activation_payload.dart';
import '../models/user_update_payload.dart';
import '../services/csv_export_service.dart';

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
  bool _isDeletingJob = false;
  String? _jobDeleteError;

  // ---- Job applications (worker requests — oversight / moderation) ----------
  List<AdminJobApplicationModel> _jobApplications = [];
  bool _isLoadingJobApplications = false;
  String? _jobApplicationsError;
  bool _isDeletingJobApplication = false;
  String? _jobApplicationDeleteError;

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

  // ---- Reports --------------------------------------------------------------
  ReportData _reportData = const ReportData();
  bool _isLoadingReports = false;
  String? _reportsError;
  bool _isExporting = false;
  String? _exportMessage;
  String? _lastExportPath;
  final CsvExportService _csvExport = CsvExportService();

  // ---- Notifications --------------------------------------------------------
  List<AdminNotificationModel> _notifications = [];
  bool _isLoadingNotifications = false;
  String? _notificationsError;
  bool _isSendingNotification = false;
  String? _sendMessage;
  int _sendProgress = 0;
  int _sendTotal = 0;
  bool _isDeletingNotification = false;

  // ---- Market / Analytics ---------------------------------------------------
  MarketAnalyticsData _marketAnalytics = const MarketAnalyticsData();
  bool _isLoadingMarket = false;
  String? _marketError;

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
  bool get isDeletingJob => _isDeletingJob;
  String? get jobDeleteError => _jobDeleteError;

  List<AdminJobApplicationModel> get jobApplications => _jobApplications;
  bool get isLoadingJobApplications => _isLoadingJobApplications;
  String? get jobApplicationsError => _jobApplicationsError;
  bool get isDeletingJobApplication => _isDeletingJobApplication;
  String? get jobApplicationDeleteError => _jobApplicationDeleteError;

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

  ReportData get reportData => _reportData;
  bool get isLoadingReports => _isLoadingReports;
  String? get reportsError => _reportsError;
  bool get isExporting => _isExporting;
  String? get exportMessage => _exportMessage;
  String? get lastExportPath => _lastExportPath;

  List<AdminNotificationModel> get notifications => _notifications;
  bool get isLoadingNotifications => _isLoadingNotifications;
  String? get notificationsError => _notificationsError;
  bool get isSendingNotification => _isSendingNotification;
  String? get sendMessage => _sendMessage;
  int get sendProgress => _sendProgress;
  int get sendTotal => _sendTotal;
  bool get isDeletingNotification => _isDeletingNotification;

  MarketAnalyticsData get marketAnalytics => _marketAnalytics;
  bool get isLoadingMarket => _isLoadingMarket;
  String? get marketError => _marketError;

  // ---------------------------------------------------------------------------
  // Market / Analytics (Phase 2, Item 7)
  // ---------------------------------------------------------------------------

  /// Loads the market / matching analytics from the existing read endpoints
  /// (`/Users`, `/Role`, `/JobPostings`, `/JobApplications`, `/Category`).
  ///
  /// No dedicated backend endpoint exists, so everything is aggregated
  /// client-side over the paginated collections.
  Future<void> loadMarketAnalytics() async {
    _isLoadingMarket = true;
    _marketError = null;
    notifyListeners();

    try {
      final results = await Future.wait<Object>([
        _repository.fetchUsers(pageSize: 500),
        _repository.fetchRoles(),
        _repository.fetchJobPostings(pageSize: 500),
        _repository.fetchJobApplications(pageSize: 500),
        _repository.fetchCategories(),
      ]);

      final allUsers = (results[0] as List<AdminUserModel>);
      final roles = (results[1] as List<RoleModel>);
      final allJobs = (results[2] as List<AdminJobPostingModel>);
      final allApplications = (results[3] as List<AdminJobApplicationModel>);
      final categories = (results[4] as List<CategoryModel>);

      _marketAnalytics = _buildMarketAnalytics(
        users: allUsers,
        roles: roles,
        jobs: allJobs,
        applications: allApplications,
        categories: categories,
      );
      _isLoadingMarket = false;
    } catch (e) {
      _isLoadingMarket = false;
      _marketError = e.toString();
    }
    notifyListeners();
  }

  MarketAnalyticsData _buildMarketAnalytics({
    required List<AdminUserModel> users,
    required List<RoleModel> roles,
    required List<AdminJobApplicationModel> applications,
    required List<AdminJobPostingModel> jobs,
    required List<CategoryModel> categories,
  }) {
    String normalize(String s) => s.toLowerCase();

    // --- Matching KPIs ------------------------------------------------------
    final openJobs =
        jobs.where((j) => normalize(j.status) == 'open').toList();
    final totalOpenJobs = openJobs.length;
    final totalApplications = applications.length;

    final pending = applications
        .where((a) => normalize(a.status) == 'pending')
        .length;
    final accepted = applications
        .where((a) => normalize(a.status) == 'accepted')
        .length;
    final rejected = applications
        .where((a) => normalize(a.status) == 'rejected')
        .length;

    // Average applications per open job (= supply meeting demand per listing).
    final avgPerOpenJob =
        totalOpenJobs == 0 ? 0.0 : totalApplications / totalOpenJobs;

    // --- Underserved demand: open jobs with 0 applications -------------------
    // Compare the application count reported on each job against the actual
    // application rows we loaded. Use the greater of the two so a job with
    // applications that fall outside our 500-page window is not flagged as
    // underserved. Underserved == an open job with no applications at all.
    final underServed = <UnderServedJobRow>[];
    for (final job in openJobs) {
      final actualCount =
          applications.where((a) => a.jobPostingId == job.id).length;
      final effectiveCount =
          actualCount > job.applicationCount ? actualCount : job.applicationCount;
      if (effectiveCount == 0) {
        underServed.add(
          UnderServedJobRow(
            id: job.id,
            title: job.title,
            categoryName: job.categoryName,
            cityName: job.cityName,
            applicationCount: 0,
            paymentAmount: job.paymentAmount,
          ),
        );
      }
    }
    underServed.sort((a, b) => b.paymentAmount.compareTo(a.paymentAmount));

    // --- Demand concentration by category -------------------------------------
    final categoryDemand = <CategoryDemandRow>[];
    for (final cat in categories) {
      final catJobs = jobs.where((j) => j.categoryId == cat.id).toList();
      final catOpen = catJobs.where((j) => normalize(j.status) == 'open').length;
      final catApplications = applications
          .where((a) => catJobs.any((j) => j.id == a.jobPostingId))
          .length;
      if (catOpen > 0 || catApplications > 0) {
        categoryDemand.add(
          CategoryDemandRow(
            category: cat.name,
            openJobs: catOpen,
            totalJobs: catJobs.length,
            applications: catApplications,
          ),
        );
      }
    }
    categoryDemand.sort(
        (a, b) => b.openJobs != a.openJobs
            ? b.openJobs.compareTo(a.openJobs)
            : b.applications.compareTo(a.applications),
    );

    // --- Demand concentration by city -----------------------------------------
    final cityNames = <String>{
      for (final j in jobs)
        if (j.cityName.isNotEmpty) j.cityName,
    };
    final cityDemand = <CityDemandRow>[];
    for (final city in cityNames) {
      final cityJobs = jobs.where((j) => j.cityName == city).toList();
      final cityOpen =
          cityJobs.where((j) => normalize(j.status) == 'open').length;
      final cityApplications = applications
          .where((a) => cityJobs.any((j) => j.id == a.jobPostingId))
          .length;
      cityDemand.add(
        CityDemandRow(
          city: city,
          openJobs: cityOpen,
          totalJobs: cityJobs.length,
          applications: cityApplications,
        ),
      );
    }
    cityDemand.sort((a, b) => b.openJobs.compareTo(a.openJobs));

    // --- Labor supply by role ---------------------------------------------------
    // Active, distinct workers (users with a role containing "worker").
    final laborSupply = <LaborSupplyRow>[];
    for (final role in roles) {
      if (!normalize(role.name).contains('worker')) continue;
      final activeWorkers = users
          .where((u) =>
              u.isActive && u.roles.any((r) => normalize(r.name).contains('worker')))
          .length;
      laborSupply.add(LaborSupplyRow(role: role.name, activeWorkers: activeWorkers));
    }
    laborSupply.sort((a, b) => b.activeWorkers.compareTo(a.activeWorkers));

    return MarketAnalyticsData(
      totalOpenJobs: totalOpenJobs,
      totalApplications: totalApplications,
      pendingApplications: pending,
      acceptedApplications: accepted,
      rejectedApplications: rejected,
      activeWorkers: laborSupply.fold<int>(
          0, (sum, r) => sum + r.activeWorkers),
      averageApplicationsPerOpenJob: avgPerOpenJob,
      avgOpenJobApplicationsOverride: avgPerOpenJob,
      underServedJobs: underServed,
      categoryDemand: categoryDemand,
      cityDemand: cityDemand,
      laborSupply: laborSupply,
    );
  }

  // ---------------------------------------------------------------------------
  // Reports (Phase 2, Item 2)
  // ---------------------------------------------------------------------------

  /// Computes the three report tables client-side from the existing read
  /// endpoints (there is no dedicated analytics endpoint).
  Future<void> loadReports() async {
    _isLoadingReports = true;
    _reportsError = null;
    notifyListeners();

    try {
      final results = await Future.wait<Object>([
        _repository.fetchUsers(pageSize: 500),
        _repository.fetchRoles(),
        _repository.fetchJobPostings(pageSize: 500),
        _repository.fetchCategories(),
        _repository.fetchReviews(pageSize: 500),
      ]);

      final allUsers = (results[0] as List<AdminUserModel>);
      final allRoles = (results[1] as List<RoleModel>);
      final allJobs = (results[2] as List<AdminJobPostingModel>);
      final categories = (results[3] as List<CategoryModel>);
      final allReviews = (results[4] as List<AdminReviewModel>);

      _reportData = _buildReportData(
        users: allUsers,
        roles: allRoles,
        jobs: allJobs,
        categories: categories,
        reviews: allReviews,
      );
      _isLoadingReports = false;
    } catch (e) {
      _isLoadingReports = false;
      _reportsError = e.toString();
    }
    notifyListeners();
  }

  ReportData _buildReportData({
    required List<AdminUserModel> users,
    required List<RoleModel> roles,
    required List<AdminJobPostingModel> jobs,
    required List<CategoryModel> categories,
    required List<AdminReviewModel> reviews,
  }) {
    final activeUsers = users.where((u) => u.isActive).length;

    // Users by role: derive from all known roles, but include any role string
    // actually present on a user even if the role list is out of sync.
    final roleSet = {for (final r in roles) r.name};
    for (final u in users) {
      for (final r in u.roles) {
        roleSet.add(r.name);
      }
    }
    String normalize(String s) => s.toLowerCase();

    final roleNames = roleSet.toList();
    roleNames.sort();
    final usersByRole = <UserReportRow>[];
    for (final roleName in roleNames) {
      final inRole = users.where(
        (u) => u.roles.any((r) => normalize(r.name) == normalize(roleName)),
      ).length;
      usersByRole.add(
        UserReportRow(
          role: roleName,
          total: inRole,
          active: users
              .where((u) =>
                  u.isActive &&
                  u.roles.any((r) => normalize(r.name) == normalize(roleName)))
              .length,
          inactive: users
              .where((u) =>
                  !u.isActive &&
                  u.roles.any((r) => normalize(r.name) == normalize(roleName)))
              .length,
        ),
      );
    }

    // Jobs by status (known lifecycle statuses).
    const statuses = ['Open', 'InProgress', 'Completed', 'Cancelled'];
    final jobsByStatus = <JobStatusRow>[];
    for (final status in statuses) {
      jobsByStatus.add(
        JobStatusRow(
          status: status,
          count: jobs.where((j) => j.status.toLowerCase() == status.toLowerCase()).length,
        ),
      );
    }

    // Jobs by category (reuse the category list for consistent ordering).
    final jobsByCategory = <JobCategoryRow>[];
    for (final cat in categories) {
      final count = jobs.where((j) => j.categoryId == cat.id).length;
      if (count > 0) {
        jobsByCategory.add(JobCategoryRow(category: cat.name, count: count));
      }
    }
    jobsByCategory.sort((a, b) => b.count.compareTo(a.count));

    // Reviews: total, average rating, count per rating bucket.
    final totalReviews = reviews.length;
    final ratingSum = reviews.fold<int>(0, (sum, r) => sum + r.rating);
    final averageRating =
        totalReviews == 0 ? 0.0 : ratingSum / totalReviews;
    final reviewsByRating = <ReviewRatingRow>[];
    for (var star = 1; star <= 5; star++) {
      reviewsByRating.add(
        ReviewRatingRow(
          rating: star,
          count: reviews.where((r) => r.rating == star).length,
        ),
      );
    }

    return ReportData(
      totalUsers: users.length,
      activeUsers: activeUsers,
      inactiveUsers: users.length - activeUsers,
      usersByRole: usersByRole,
      totalJobs: jobs.length,
      jobsByStatus: jobsByStatus,
      jobsByCategory: jobsByCategory,
      totalReviews: totalReviews,
      averageRating: averageRating,
      reviewsByRating: reviewsByRating,
    );
  }

  /// Serializes the currently-loaded reports into a single combined CSV
  /// (one file with a labelled section per report).
  String buildCombinedCsv() {
    final d = _reportData;
    final b = StringBuffer();

    // -- Users ----------------------------------------------------------------
    b.writeln('USERS REPORT');
    b.writeln('Total users,${d.totalUsers}');
    b.writeln('Active users,${d.activeUsers}');
    b.writeln('Inactive users,${d.inactiveUsers}');
    b.writeln('Role,Total,Active,Inactive');
    for (final row in d.usersByRole) {
      b.writeln('${escapeCsv(row.role)},${row.total},${row.active},${row.inactive}');
    }

    b.writeln();

    // -- Jobs -----------------------------------------------------------------
    b.writeln('JOBS REPORT');
    b.writeln('Total jobs,${d.totalJobs}');
    b.writeln('Status,Count');
    for (final row in d.jobsByStatus) {
      b.writeln('${escapeCsv(row.status)},${row.count}');
    }
    b.writeln('Category,Count');
    for (final row in d.jobsByCategory) {
      b.writeln('${escapeCsv(row.category)},${row.count}');
    }

    b.writeln();

    // -- Reviews --------------------------------------------------------------
    b.writeln('REVIEWS REPORT');
    b.writeln('Total reviews,${d.totalReviews}');
    b.writeln('Average rating,${d.averageRating.toStringAsFixed(2)}');
    b.writeln('Rating,Count');
    for (final row in d.reviewsByRating) {
      b.writeln('${row.rating} star,${row.count}');
    }

    return b.toString();
  }

  /// Writes the combined CSV to a fixed, well-known location via
  /// [CsvExportService]. [exportDirOverride] lets tests inject a directory.
  Future<void> exportReports({Directory? exportDirOverride}) async {
    _isExporting = true;
    _exportMessage = null;
    _lastExportPath = null;
    notifyListeners();

    try {
      final content = buildCombinedCsv();
      final path = await _csvExport.export(
        content: content,
        getDir:
            exportDirOverride == null ? null : () async => exportDirOverride,
      );
      _isExporting = false;
      if (path == null) {
        _exportMessage = 'Could not determine a location to write the export.';
      } else {
        _lastExportPath = path;
        _exportMessage = 'Exported to $path';
      }
    } catch (e) {
      _isExporting = false;
      _exportMessage = 'Export failed: $e';
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Notifications (announcements)
  // ---------------------------------------------------------------------------

  /// Loads the most recent notifications (last N) for the history list.
  Future<void> loadNotifications({int pageSize = 10}) async {
    _isLoadingNotifications = true;
    _notificationsError = null;
    notifyListeners();

    try {
      _notifications =
          await _repository.fetchNotifications(pageSize: pageSize);
      _isLoadingNotifications = false;
    } catch (e) {
      _isLoadingNotifications = false;
      _notificationsError = e.toString();
    }
    notifyListeners();
  }

  /// Sends an announcement to **every** user.
  ///
  /// The backend `POST /Notifications` only accepts a single `UserId`, so the
  /// broadcast is a client-side fan-out: fetch all users, then create one
  /// notification per user. On success the history is refreshed.
  Future<bool> sendAnnouncement({
    required String title,
    required String message,
    String type = 'announcement',
  }) async {
    _isSendingNotification = true;
    _sendMessage = null;
    _sendProgress = 0;
    _sendTotal = 0;
    notifyListeners();

    try {
      final allUsers = await _repository.fetchUsers(pageSize: 500);
      _sendTotal = allUsers.length;

      var sent = 0;
      var failed = 0;
      for (final user in allUsers) {
        try {
          await _repository.createNotification(
            NotificationPayload(
              userId: user.id,
              type: type,
              title: title,
              message: message,
            ),
          );
          sent++;
        } catch (_) {
          failed++;
        }
        _sendProgress = sent + failed;
        notifyListeners();
      }

      _isSendingNotification = false;
      _sendMessage = 'Announcement sent to $sent user(s)'
          '${failed > 0 ? ' ($failed failed)' : ''}.';
      notifyListeners();

      // Refresh history so the latest sends show up.
      await loadNotifications();
      return failed == 0;
    } catch (e) {
      _isSendingNotification = false;
      _sendMessage = 'Could not send announcement: $e';
      notifyListeners();
      return false;
    }
  }

  /// Removes a notification and refreshes the history.
  Future<bool> deleteNotification(AdminNotificationModel notification) async {
    _isDeletingNotification = true;
    notifyListeners();

    try {
      await _repository.deleteNotification(notification.id);
      _notifications =
          _notifications.where((n) => n.id != notification.id).toList();
      _isDeletingNotification = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isDeletingNotification = false;
      _notificationsError = e.toString();
      notifyListeners();
      return false;
    }
  }

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

  /// Removes (hard-deletes) a user-posted job and its cascaded data
  /// (applications, messages, reviews, payments) via `DELETE /JobPostings/{id}`.
  ///
  /// On success the job is dropped from the local list; on failure the row is
  /// kept and [jobDeleteError] is set.
  Future<bool> deleteJob(AdminJobPostingModel job) async {
    _isDeletingJob = true;
    _jobDeleteError = null;
    notifyListeners();

    try {
      await _repository.deleteJob(job.id);
      _jobs = _jobs.where((j) => j.id != job.id).toList();
      _isDeletingJob = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isDeletingJob = false;
      _jobDeleteError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Job applications (worker requests — oversight / moderation)
  // ---------------------------------------------------------------------------

  /// Loads job applications (worker requests) with an optional [status] filter.
  Future<void> loadJobApplications({String? status}) async {
    _isLoadingJobApplications = true;
    _jobApplicationsError = null;
    notifyListeners();

    try {
      final result =
          await _repository.fetchJobApplications(status: status, pageSize: 200);
      _jobApplications = result;
      _isLoadingJobApplications = false;
    } catch (e) {
      _isLoadingJobApplications = false;
      _jobApplicationsError = e.toString();
    }
    notifyListeners();
  }

  /// Removes (hard-deletes) a job application / request as a moderation action.
  ///
  /// On success the row is dropped from the local list; on failure it is kept
  /// and [jobApplicationDeleteError] is set.
  Future<bool> deleteJobApplication(AdminJobApplicationModel application) async {
    _isDeletingJobApplication = true;
    _jobApplicationDeleteError = null;
    notifyListeners();

    try {
      await _repository.deleteJobApplication(application.id);
      _jobApplications =
          _jobApplications.where((a) => a.id != application.id).toList();
      _isDeletingJobApplication = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isDeletingJobApplication = false;
      _jobApplicationDeleteError = e.toString();
      notifyListeners();
      return false;
    }
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

/// Quotes/escapes a single CSV field so commas, quotes and newlines do not
/// corrupt the column layout.
String escapeCsv(String value) {
  final needsQuoting =
      value.contains(',') || value.contains('"') || value.contains('\n');
  if (!needsQuoting) return value;
  return '"${value.replaceAll('"', '""')}"';
}
