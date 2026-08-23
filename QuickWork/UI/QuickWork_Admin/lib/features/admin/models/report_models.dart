/// Data classes for the admin "Reports" module (Phase 2, Item 2).
///
/// These models hold the client-side aggregates computed from the existing
/// paginated read endpoints (`/Users`, `/JobPostings`, `/Reviews`, `/Role`,
/// `/Category`). None of them correspond to a dedicated backend endpoint.
library;

/// One row of the **Users report**: total / active / inactive users per role.
class UserReportRow {
  const UserReportRow({
    required this.role,
    required this.total,
    required this.active,
    required this.inactive,
  });

  final String role;
  final int total;
  final int active;
  final int inactive;
}

/// One row of the **Jobs by status** section.
class JobStatusRow {
  const JobStatusRow({required this.status, required this.count});

  final String status;
  final int count;
}

/// One row of the **Jobs by category** section.
class JobCategoryRow {
  const JobCategoryRow({required this.category, required this.count});

  final String category;
  final int count;
}

/// One row of the **Reviews by rating bucket** section (1..5 stars).
class ReviewRatingRow {
  const ReviewRatingRow({required this.rating, required this.count});

  final int rating;
  final int count;
}

/// Immutable snapshot of every aggregate produced for the Reports screen.
///
/// The screen can render directly from this and the provider can expose a
/// combined CSV string for export.
class ReportData {
  const ReportData({
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.inactiveUsers = 0,
    this.usersByRole = const [],
    this.totalJobs = 0,
    this.jobsByStatus = const [],
    this.jobsByCategory = const [],
    this.totalReviews = 0,
    this.averageRating = 0.0,
    this.reviewsByRating = const [],
  });

  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;
  final List<UserReportRow> usersByRole;

  final int totalJobs;
  final List<JobStatusRow> jobsByStatus;
  final List<JobCategoryRow> jobsByCategory;

  final int totalReviews;
  final double averageRating;
  final List<ReviewRatingRow> reviewsByRating;
}
