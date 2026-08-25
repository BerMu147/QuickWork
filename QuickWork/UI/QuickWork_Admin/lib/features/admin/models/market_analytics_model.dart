import 'dart:ui';

/// Data classes for the admin "Market / Analytics" module (Phase 2, Item 7).
///
/// These models hold the client-side aggregates computed from the existing
/// paginated read endpoints (`/JobPostings`, `/JobApplications`, `/Users`,
/// `/Category`). None of them correspond to a dedicated backend endpoint.

/// One row of the **open jobs with few/no applications** ("underserved
/// demand") table. These are open jobs whose application_count is below the
/// threshold, i.e. demand that is not yet being met by sufficient supply
/// (workers applying).
class UnderServedJobRow {
  const UnderServedJobRow({
    required this.id,
    required this.title,
    required this.categoryName,
    required this.cityName,
    required this.applicationCount,
    required this.paymentAmount,
  });

  final int id;
  final String title;
  final String categoryName;
  final String cityName;
  final int applicationCount;
  final double paymentAmount;
}

/// One row of the **jobs-by-category** demand concentration table.
class CategoryDemandRow {
  const CategoryDemandRow({
    required this.category,
    required this.openJobs,
    required this.totalJobs,
    required this.applications,
  });

  final String category;
  final int openJobs;
  final int totalJobs;
  final int applications;
}

/// One row of the **jobs-by-city** demand concentration table.
class CityDemandRow {
  const CityDemandRow({
    required this.city,
    required this.openJobs,
    required this.totalJobs,
    required this.applications,
  });

  final String city;
  final int openJobs;
  final int totalJobs;
  final int applications;
}

/// One row of the **labor supply** table — active workers per role.
class LaborSupplyRow {
  const LaborSupplyRow({
    required this.role,
    required this.activeWorkers,
  });

  final String role;
  final int activeWorkers;
}

/// A KPI value describing a matching/market metric.
class MatchingKpi {
  const MatchingKpi({
    required this.label,
    required this.value,
    this.color = const Color(0xFF129ACA),
  });

  final String label;
  final Object value;
  final Color color;
}

/// Immutable snapshot of every aggregate produced for the Market/Analytics
/// screen. The screen renders entirely from this.
class MarketAnalyticsData {
  const MarketAnalyticsData({
    this.totalOpenJobs = 0,
    this.totalApplications = 0,
    this.pendingApplications = 0,
    this.acceptedApplications = 0,
    this.rejectedApplications = 0,
    this.activeWorkers = 0,
    this.averageApplicationsPerOpenJob = 0.0,
    this.avgOpenJobApplicationsOverride = 0.0,
    this.underServedJobs = const [],
    this.categoryDemand = const [],
    this.cityDemand = const [],
    this.laborSupply = const [],
  });

  final int totalOpenJobs;
  final int totalApplications;
  final int pendingApplications;
  final int acceptedApplications;
  final int rejectedApplications;
  final int activeWorkers;

  /// Average number of applications across **all** jobs.
  final double averageApplicationsPerOpenJob;

  /// Average number of applications across open jobs only (avoids dividing
  /// by zero when there are no open jobs).
  final double avgOpenJobApplicationsOverride;

  final List<UnderServedJobRow> underServedJobs;
  final List<CategoryDemandRow> categoryDemand;
  final List<CityDemandRow> cityDemand;
  final List<LaborSupplyRow> laborSupply;
}

