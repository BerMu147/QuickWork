import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../models/job_application_model.dart';
import '../providers/job_posting_provider.dart';
import '../widgets/job_posting_card.dart';
import 'job_detail_screen.dart';

/// The "My Jobs" tab — shows the jobs the user published and the applications
/// they submitted (and receive). Requires an account.
class MyJobsScreen extends StatelessWidget {
  const MyJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    // Not logged in? Prompt the user to sign in.
    if (!auth.isAuthenticated) {
      return _LoginPrompt(theme: theme);
    }

    final user = auth.user!;

    // Trigger loading of the user's data when first shown.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<JobPostingProvider>();
      if (provider.myJobPostings.isEmpty && provider.myApplications.isEmpty) {
        provider.loadMyJobs(user.id);
      }
    });

    return DefaultTabController(
      length: 2,
      child: Builder(builder: (context) {
        return Column(
          children: [
            const Material(
              color: Colors.white,
              child: TabBar(
                labelColor: AppConstants.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppConstants.primary,
                tabs: [
                  Tab(text: 'Published'),
                  Tab(text: 'Applications'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _PublishedJobs(),
                  _SubmittedApplications(),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// Shown when a guest opens the "My Jobs" tab.
class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Log in to see your jobs and applications.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.login),
              label: const Text('Log in'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab: jobs the current user has published.
class _PublishedJobs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobPostingProvider>();

    if (provider.isLoadingMyJobs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.myJobPostings.isEmpty) {
      return const _EmptyState(
        icon: Icons.work_off_outlined,
        message: 'You have not published any jobs yet.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final auth = context.read<AuthProvider>();
        final p = context.read<JobPostingProvider>();
        await p.loadMyJobs(auth.user?.id ?? 0);
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8),
        itemCount: provider.myJobPostings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final job = provider.myJobPostings[index];
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
      ),
    );
  }
}

/// Tab: applications the current user submitted.
class _SubmittedApplications extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobPostingProvider>();

    if (provider.isLoadingMyJobs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.myApplications.isEmpty) {
      return const _EmptyState(
        icon: Icons.outbox_outlined,
        message: 'You have not applied to any jobs yet.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final auth = context.read<AuthProvider>();
        final p = context.read<JobPostingProvider>();
        await p.loadMyJobs(auth.user?.id ?? 0);
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8),
        itemCount: provider.myApplications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final app = provider.myApplications[index];
          return _ApplicationCard(application: app);
        },
      ),
    );
  }
}

/// A simple empty-state widget.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 56, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }
}

/// A card showing one submitted/published application.
class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application});

  final JobApplicationModel application;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        title: Text(
          application.jobPostingTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Status: ${application.status}'),
            if (application.appliedAt != null)
              Text(
                'Applied: ${application.appliedAt!.day}.${application.appliedAt!.month}.${application.appliedAt!.year}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        trailing: _StatusBadge(status: application.status),
      ),
    );
  }
}

/// A colored status badge (Pending / Accepted / Rejected / Withdrawn).
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Accepted' => Colors.green,
      'Rejected' => Colors.red,
      'Withdrawn' => Colors.grey,
      _ => Colors.orange,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
