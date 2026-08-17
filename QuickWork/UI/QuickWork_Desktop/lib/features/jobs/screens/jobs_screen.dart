import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/job_posting_repository.dart';
import '../providers/job_posting_provider.dart';
import '../screens/job_detail_screen.dart';
import '../screens/search_job_screen.dart';
import '../widgets/job_posting_card.dart';

/// Displays the list of available job postings. Reachable by everyone
/// (guests can browse; applying requires an account).
class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  JobPostingQuery? _activeQuery;

  @override
  void initState() {
    super.initState();
    // Load jobs once on first build. Post-frame avoids setState during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<JobPostingProvider>();
      if (provider.jobPostings.isEmpty) {
        provider.loadJobPostings();
      }
    });
  }

  Future<void> _refresh() async {
    await context.read<JobPostingProvider>().loadJobPostings(query: _activeQuery);
  }

  Future<void> _openSearch() async {
    final result = await Navigator.of(context).push<JobPostingQuery>(
      MaterialPageRoute(
        builder: (_) => SearchJobScreen(initialQuery: _activeQuery),
      ),
    );

    if (!mounted || result == null) return;

    setState(() => _activeQuery = result);
    await context.read<JobPostingProvider>().loadJobPostings(query: result);
  }

  Future<void> _clearFilters() async {
    setState(() => _activeQuery = null);
    await context.read<JobPostingProvider>().loadJobPostings();
  }

  bool get _isFiltered =>
      _activeQuery?.title != null ||
      _activeQuery?.categoryId != null ||
      _activeQuery?.cityId != null;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobPostingProvider>();

    return Column(
      children: [
        _SearchBar(onTap: _openSearch, isFiltered: _isFiltered),
        if (_isFiltered) _ActiveFilterChip(query: _activeQuery!, onClear: _clearFilters),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: _buildBody(provider),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(JobPostingProvider provider) {
    // Loading state.
    if (provider.isLoading && provider.jobPostings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state.
    if (provider.error != null && provider.jobPostings.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            provider.error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: _refresh,
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    // Empty state.
    if (provider.jobPostings.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.work_off_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _isFiltered
                ? 'No jobs match your filters.'
                : 'No jobs available right now.',
            textAlign: TextAlign.center,
          ),
          if (_isFiltered) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear filters'),
              ),
            ),
          ],
        ],
      );
    }

    // Job list.
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: provider.jobPostings.length,
      itemBuilder: (context, index) {
        final job = provider.jobPostings[index];
        return JobPostingCard(
          job: job,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => JobDetailScreen(jobId: job.id),
              ),
            );
          },
        );
      },
    );
  }
}

/// A tappable faux-search bar at the top of the Jobs screen.
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap, required this.isFiltered});

  final VoidCallback onTap;
  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Material(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isFiltered ? 'Edit filters' : 'Search jobs...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 15),
                  ),
                ),
                if (isFiltered)
                  Icon(Icons.filter_alt, color: Colors.grey[600], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small chip showing that filters are active and offering to clear them.
class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.query, required this.onClear});

  final JobPostingQuery query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (query.title?.isNotEmpty == true) '“${query.title}”',
      if (query.categoryId != null) 'category',
      if (query.cityId != null) 'city',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ActionChip(
          avatar: const Icon(Icons.filter_alt, size: 18),
          label: Text('Filters: ${parts.join(', ')}'),
          onPressed: onClear,
          labelStyle: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }
}

