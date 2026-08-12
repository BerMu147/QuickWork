import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../providers/job_posting_provider.dart';
import 'conversation_screen.dart';

/// Shows the full detail of a single job posting with an Apply button.
///
/// Applying requires an account: a guest who taps Apply is prompted to log in
/// first (like an online shop where you browse freely but check out with an
/// account).
class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({super.key, required this.jobId});

  final int jobId;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _applied = false;

  Future<void> _handleApply() async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<JobPostingProvider>();
    final job = provider.byId(widget.jobId);

    // Step 1 — ensure the user is logged in.
    if (!auth.isAuthenticated) {
      // Prompt the guest to log in (or register) before applying.
      final loggedIn = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (loggedIn != true || !mounted) return;
    }

    if (job == null) return;

    // Step 2 — submit the application.
    final success = await provider.applyToJob(
      jobPostingId: job.id,
      applicantUserId: auth.user?.id ?? 0,
    );

    if (!mounted) return;

    if (success) {
      setState(() => _applied = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobPostingProvider>();
    final auth = context.watch<AuthProvider>();
    final job = provider.byId(widget.jobId);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job details'),
        backgroundColor: AppConstants.primary,
      ),
      body: job == null
          ? const Center(child: Text('Job not found.'))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppConstants.pagePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: AppConstants.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.location_on_outlined,
                          label:
                              '${job.cityName}${job.address != null ? ', ${job.address}' : ''}',
                        ),
                        _DetailRow(
                          icon: Icons.category_outlined,
                          label: job.categoryName,
                        ),
                        _DetailRow(
                          icon: Icons.person_outline,
                          label: job.postedByUserName,
                        ),
                        _DetailRow(
                          icon: Icons.schedule,
                          label:
                              '${job.scheduledTimeStart ?? ''} – ${job.scheduledTimeEnd ?? ''}',
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Description',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          job.description,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(
                                AppConstants.defaultRadius),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${job.paymentAmount.toStringAsFixed(2)} KM',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: AppConstants.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Scheduled: ${job.scheduledDate.day}.${job.scheduledDate.month}.${job.scheduledDate.year}',
                                style: theme.textTheme.bodyMedium,
                              ),
                              if (job.estimatedDurationHours != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Est. duration: ${job.estimatedDurationHours!.toStringAsFixed(0)} h',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (provider.applicationError != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(
                                  AppConstants.defaultRadius),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: theme.colorScheme.error),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    provider.applicationError!,
                                    style: TextStyle(
                                        color: theme
                                            .colorScheme.onErrorContainer),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ),
                // Bottom action bar.
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: _buildApplyButton(auth, provider),
                        ),
                        if (auth.isAuthenticated &&
                            auth.user?.id != job.postedByUserId) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ConversationScreen(
                                      jobPostingId: job.id,
                                      jobTitle: job.title,
                                      otherUserId: job.postedByUserId,
                                      otherUserName: job.postedByUserName,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('Message the publisher'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildApplyButton(AuthProvider auth, JobPostingProvider provider) {
    if (_applied) {
      return ElevatedButton.icon(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          disabledBackgroundColor: Colors.green,
        ),
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
        label: const Text(
          'Applied',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final label = auth.isAuthenticated
        ? 'Apply for this job'
        : 'Log in to apply';

    return ElevatedButton.icon(
      onPressed: provider.isApplying ? null : _handleApply,
      icon: provider.isApplying
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Icon(auth.isAuthenticated
              ? Icons.send_outlined
              : Icons.lock_outline),
      label: Text(provider.isApplying ? 'Applying...' : label),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

