import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../models/report_models.dart';
import '../providers/admin_provider.dart';

/// The "Reports" module of the administrator console (Phase 2, Item 2).
///
/// Presents three aggregate tables — Users, Jobs and Reviews — computed
/// client-side from the existing read endpoints, with a single combined
/// CSV export written to a fixed, well-known location.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdminProvider>();
      if (provider.reportData.totalUsers == 0 &&
          !provider.isLoadingReports &&
          provider.reportsError == null) {
        provider.loadReports();
      }
    });
  }

  Future<void> _refresh() async {
    await context.read<AdminProvider>().loadReports();
  }

  Future<void> _export() async {
    // Export always produces the single combined CSV regardless of the tab.
    await context.read<AdminProvider>().exportReports();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final data = admin.reportData;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: AppConstants.primary,
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed:
                admin.isLoadingReports || admin.isExporting ? null : _export,
            icon: admin.isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: admin.isLoadingReports && data.totalUsers == 0
            ? const Center(child: CircularProgressIndicator())
            : admin.reportsError != null && data.totalUsers == 0
                ? _ErrorState(
                    message: admin.reportsError!, onRetry: _refresh)
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppConstants.pagePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (admin.reportsError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ErrorStrip(message: admin.reportsError!),
                          ),
                        if (admin.exportMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ExportNotice(
                              message: admin.exportMessage!,
                              path: admin.lastExportPath,
                            ),
                          ),
                        _buildTabBar(tabIndex: _tabIndex, onChanged: (i) {
                          setState(() => _tabIndex = i);
                        }),
                        const SizedBox(height: 16),
                        if (_tabIndex == 0) _buildUsersReport(data, theme),
                        if (_tabIndex == 1) _buildJobsReport(data, theme),
                        if (_tabIndex == 2) _buildReviewsReport(data, theme),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildTabBar({
    required int tabIndex,
    required ValueChanged<int> onChanged,
  }) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 0, label: Text('Users')),
        ButtonSegment(value: 1, label: Text('Jobs')),
        ButtonSegment(value: 2, label: Text('Reviews')),
      ],
      selected: {tabIndex},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }

  Widget _buildUsersReport(ReportData data, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _Kpi(label: 'Total users', value: data.totalUsers)),
            const SizedBox(width: 8),
            Expanded(
              child: _Kpi(
                label: 'Active',
                value: data.activeUsers,
                color: const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Kpi(
                label: 'Inactive',
                value: data.inactiveUsers,
                color: const Color(0xFFEF5350),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Users by role',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: data.usersByRole.isEmpty
                ? const Text('No users found.')
                : Column(
                    children: [
                      for (final row in data.usersByRole)
                        _Row3(
                          label: row.role,
                          c1: '${row.total}',
                          c2: '${row.active}',
                          c3: '${row.inactive}',
                          header1: 'Total',
                          header2: 'Active',
                          header3: 'Inactive',
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildJobsReport(ReportData data, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _Kpi(label: 'Total jobs', value: data.totalJobs),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Jobs by status',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (final row in data.jobsByStatus)
                  _Row2(label: row.status, header: 'Count', value: row.count),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Jobs by category',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: data.jobsByCategory.isEmpty
                ? const Text('No jobs posted yet.')
                : Column(
                    children: [
                      for (final row in data.jobsByCategory)
                        _Row2(
                            label: row.category,
                            header: 'Count',
                            value: row.count),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsReport(ReportData data, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _Kpi(label: 'Total reviews', value: data.totalReviews),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Kpi(
                label: 'Average rating',
                value: data.totalReviews == 0
                    ? '—'
                    : data.averageRating.toStringAsFixed(1),
                color: const Color(0xFFFF9800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Reviews by rating',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: data.totalReviews == 0
                ? const Text('No reviews yet.')
                : Column(
                    children: [
                      for (final row in data.reviewsByRating)
                        _Row2(
                          label: '${row.rating} star${row.rating == 1 ? '' : 's'}',
                          header: 'Count',
                          value: row.count,
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// Small KPI chip shown at the top of each report.
class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.label,
    required this.value,
    this.color = const Color(0xFF129ACA),
  });

  final String label;
  final Object value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

/// A two-column table row.
class _Row2 extends StatelessWidget {
  const _Row2({
    required this.label,
    required this.header,
    required this.value,
  });

  final String label;
  final String header;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(header,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                Text('$value',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A three-column table row (used for the users-by-role table).
class _Row3 extends StatelessWidget {
  const _Row3({
    required this.label,
    required this.c1,
    required this.c2,
    required this.c3,
    required this.header1,
    required this.header2,
    required this.header3,
  });

  final String label;
  final String c1;
  final String c2;
  final String c3;
  final String header1;
  final String header2;
  final String header3;

  @override
  Widget build(BuildContext context) {
    Widget col(String header, String value) => Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(header,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          SizedBox(width: 60, child: col(header1, c1)),
          SizedBox(width: 60, child: col(header2, c2)),
          SizedBox(width: 60, child: col(header3, c3)),
        ],
      ),
    );
  }
}

/// Banner confirming a successful (or failed) CSV export.
class _ExportNotice extends StatelessWidget {
  const _ExportNotice({required this.message, this.path});

  final String message;
  final String? path;

  @override
  Widget build(BuildContext context) {
    final ok = path != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ok
            ? Colors.green.withValues(alpha: 0.12)
            : Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.error_outline,
            color: ok ? Colors.green : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: ok ? Colors.green.shade900 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _ErrorStrip extends StatelessWidget {
  const _ErrorStrip({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
