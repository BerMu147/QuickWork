import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../reviews/providers/review_provider.dart';
import '../../reviews/screens/review_form_screen.dart';
import '../models/job_application_model.dart';
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
  JobApplicationModel? _myApplication;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final provider = context.read<JobPostingProvider>();
      final job = provider.byId(widget.jobId);
      if (auth.isAuthenticated && job != null) {
        // Load my own application so we can show its status instead of a
        // (duplicate) "Apply" button. Own postings never show Apply.
        if (auth.user?.id != job.postedByUserId) {
          final myApp = await provider.applicationForJob(
            jobPostingId: widget.jobId,
            applicantUserId: auth.user?.id ?? 0,
          );
          if (!mounted) return;
          setState(() => _myApplication = myApp);
          if (myApp != null) setState(() => _applied = true);
        }
      }
    });
  }

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

  /// Whether the current user (as a hired worker) can review the publisher:
  /// the job is completed and this worker's application was accepted.
  bool get _canReviewPublisher {
    final job = context.read<JobPostingProvider>().byId(widget.jobId);
    if (job == null) return false;
    return job.status.toLowerCase() == 'completed' &&
        _myApplication?.status == 'Accepted';
  }

  /// Opens the review form so a hired worker can rate the publisher of a
  /// completed job.
  Future<void> _openReview() async {
    final auth = context.read<AuthProvider>();
    final job = context.read<JobPostingProvider>().byId(widget.jobId);
    if (auth.user == null || job == null) return;

    final reviewerId = auth.user!.id;
    final reviewerName = auth.user!.fullName;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Consumer<ReviewProvider>(
        builder: (sheetContext, reviewProvider, _) => ReviewFormScreen(
          reviewerName: reviewerName,
          reviewedName: job.postedByUserName,
          jobTitle: job.title,
          submitting: reviewProvider.isSubmitting,
          error: reviewProvider.submitError,
          onSubmit: (rating, comment) async {
            final ok = await reviewProvider.submitReview(
              reviewerUserId: reviewerId,
              reviewedUserId: job.postedByUserId,
              jobPostingId: job.id,
              rating: rating,
              comment: comment,
            );
            if (ok && sheetContext.mounted) {
              Navigator.of(sheetContext).pop(true);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Review for ${job.postedByUserName} submitted!'),
                  ),
                );
              }
            }
        },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobPostingProvider>();
    final auth = context.watch<AuthProvider>();
    final job = provider.byId(widget.jobId);
    final theme = Theme.of(context);

    final isOwner = auth.isAuthenticated && job != null
        ? auth.user?.id == job.postedByUserId
        : false;

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
                          child: _buildApplyButton(auth, provider, isOwner),
                        ),
                        if (auth.isAuthenticated &&
                            !isOwner &&
                            _canReviewPublisher) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: Consumer<ReviewProvider>(
                              builder: (context, reviewProvider, _) {
                                final reviewed = reviewProvider.hasReviewed(
                                  reviewerUserId: auth.user?.id ?? 0,
                                  jobPostingId: job.id,
                                );
                                if (reviewed) {
                                  return OutlinedButton.icon(
                                    onPressed: null,
                                    icon: const Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.green),
                                    label:
                                        const Text('You reviewed the publisher'),
                                  );
                                }
                                return FilledButton.icon(
                                  onPressed: _openReview,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.amber.shade700,
                                  ),
                                  icon: const Icon(Icons.star_outline),
                                  label: const Text('Review the publisher'),
                                );
                              },
                            ),
                          ),
                        ],
                        if (auth.isAuthenticated &&
                            !isOwner) ...[
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

  Widget _buildApplyButton(
      AuthProvider auth, JobPostingProvider provider, bool isOwner) {
    // A publisher viewing their own job cannot apply to it.
    if (isOwner) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.work_off_outlined, color: Colors.grey),
        label: const Text(
          'This is your job posting',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Already applied — show the application status instead of "Apply".
    if (_myApplication != null) {
      return _statusButton(_myApplication!.status);
    }

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

  /// A disabled button reflecting the user's current application status.
  Widget _statusButton(String status) {
    final (Color color, IconData icon, String label) = switch (status) {
      'Accepted' => (Colors.green, Icons.check_circle_outline, 'Application Accepted'),
      'Rejected' => (Colors.red, Icons.cancel_outlined, 'Application Rejected'),
      'Withdrawn' => (Colors.grey, Icons.remove_circle_outline, 'Application Withdrawn'),
      _ => (Colors.orange, Icons.schedule, 'Application Pending'),
    };

    return ElevatedButton.icon(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: color,
      ),
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
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

