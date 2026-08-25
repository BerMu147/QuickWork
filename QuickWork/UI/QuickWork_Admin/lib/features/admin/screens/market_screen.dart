import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../models/market_analytics_model.dart';
import '../providers/admin_provider.dart';

/// The "Market / Analytics" module of the administrator console (Item 7).
///
/// A matching / market analytics view that answers "where is work being
/// offered, where is it most/least contested, and is there labor supply to
/// meet it?" It is fully computed client-side from the existing read
/// endpoints (`/Users`, `/Role`, `/JobPostings`, `/JobApplications`,
/// `/Category`) — there is no dedicated analytics endpoint.
class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      if (admin.marketAnalytics.totalApplications == 0 &&
          admin.marketAnalytics.totalOpenJobs == 0 &&
          !admin.isLoadingMarket &&
          admin.marketError == null) {
        admin.loadMarketAnalytics();
      }
    });
  }

  Future<void> _refresh() async {
    await context.read<AdminProvider>().loadMarketAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final data = admin.marketAnalytics;
    final theme = Theme.of(context);
    final hasData = data.totalOpenJobs != 0 || data.totalApplications != 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Market / Analytics'),
        backgroundColor: AppConstants.primary,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: admin.isLoadingMarket && !hasData
            ? const Center(child: CircularProgressIndicator())
            : admin.marketError != null && !hasData
                ? _ErrorState(message: admin.marketError!, onRetry: _refresh)
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppConstants.pagePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (admin.marketError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ErrorStrip(message: admin.marketError!),
                          ),
                        _buildMatchingKpis(data),
                        const SizedBox(height: 20),
                        Text(
                          'Application status',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildStatusBreakdown(context, data),
                        const SizedBox(height: 24),
                        Text(
                          'Underserved demand (open jobs with no applicants)',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Open jobs that have received no applications yet — '
                          'the applicants-to-duties gaps an admin may want to '
                          'promote or re-balance.',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        _buildUnderServed(data),
                        const SizedBox(height: 24),
                        Text(
                          'Demand by category',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildCategoryDemand(data),
                        const SizedBox(height: 24),
                        Text(
                          'Demand by city',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildCityDemand(data),
                        const SizedBox(height: 24),
                        Text(
                          'Labor supply (active workers)',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildLaborSupply(context, data),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildMatchingKpis(MarketAnalyticsData data) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Open Jobs',
                value: '${data.totalOpenJobs}',
                color: const Color(0xFF129ACA),
                icon: Icons.work_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                label: 'Applications',
                value: '${data.totalApplications}',
                color: const Color(0xFF33BCDE),
                icon: Icons.handshake_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Active Workers',
                value: '${data.activeWorkers}',
                color: const Color(0xFF4CAF50),
                icon: Icons.people_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                label: 'Avg Apps / Open Job',
                value: data.averageApplicationsPerOpenJob.toStringAsFixed(1),
                color: const Color(0xFFFF9800),
                icon: Icons.analytics_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBreakdown(BuildContext context, MarketAnalyticsData data) {
    final items = [
      (label: 'Pending', value: data.pendingApplications, color: const Color(0xFFFF9800)),
      (label: 'Accepted', value: data.acceptedApplications, color: const Color(0xFF4CAF50)),
      (label: 'Rejected', value: data.rejectedApplications, color: Colors.red),
    ];

    final maxValue = items.fold<int>(
        1, (m, i) => i.value > m ? i.value : m);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: data.totalApplications == 0
            ? const Text('No applications yet.')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in items) ...[
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            item.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (item.value / maxValue).clamp(0.0, 1.0),
                              minHeight: 10,
                              backgroundColor: Colors.grey[200],
                              color: item.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 32,
                          child: Text(
                            '${item.value}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildUnderServed(MarketAnalyticsData data) {
    if (data.underServedJobs.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No uncovered open jobs — every open listing has at least one '
            'applicant.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final currency = NumberFormat.currency(symbol: '\$');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (final row in data.underServedJobs)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${row.categoryName} · ${row.cityName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currency.format(row.paymentAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDemand(MarketAnalyticsData data) {
    if (data.categoryDemand.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No jobs posted across categories yet.',
              textAlign: TextAlign.center),
        ),
      );
    }

    final maxOpen = data.categoryDemand.fold<int>(
        1, (m, r) => r.openJobs > m ? r.openJobs : m);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final row in data.categoryDemand) ...[
              Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      row.category,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (row.openJobs / maxOpen).clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: Colors.grey[200],
                        color: AppConstants.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 110,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${row.openJobs} open',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${row.totalJobs} total · ${row.applications} apps',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCityDemand(MarketAnalyticsData data) {
    if (data.cityDemand.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No jobs posted yet.', textAlign: TextAlign.center),
        ),
      );
    }

    final maxOpen =
        data.cityDemand.fold<int>(1, (m, r) => r.openJobs > m ? r.openJobs : m);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final row in data.cityDemand) ...[
              Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      row.city,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (row.openJobs / maxOpen).clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: Colors.grey[200],
                        color: const Color(0xFF33BCDE),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 110,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${row.openJobs} open',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${row.totalJobs} total · ${row.applications} apps',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLaborSupply(BuildContext context, MarketAnalyticsData data) {
    if (data.laborSupply.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No worker-role users found.',
              textAlign: TextAlign.center),
        ),
      );
    }

    final maxValue = data.laborSupply.fold<int>(
        1, (m, r) => r.activeWorkers > m ? r.activeWorkers : m);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final row in data.laborSupply) ...[
              Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      row.role,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (row.activeWorkers / maxValue).clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: Colors.grey[200],
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${row.activeWorkers}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
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
