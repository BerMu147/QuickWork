import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/job_posting_provider.dart';
import '../screens/job_detail_screen.dart';
import '../widgets/job_posting_card.dart';

/// Displays the list of available job postings. Reachable by everyone
/// (guests can browse; applying requires an account).
class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
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
    await context.read<JobPostingProvider>().loadJobPostings();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobPostingProvider>();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: _buildBody(provider),
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
        children: const [
          SizedBox(height: 120),
          Icon(Icons.work_off_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No jobs available right now.',
            textAlign: TextAlign.center,
          ),
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

