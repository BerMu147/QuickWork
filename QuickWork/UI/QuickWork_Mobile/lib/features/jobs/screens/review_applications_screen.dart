import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../reviews/providers/review_provider.dart';
import '../../reviews/screens/review_form_screen.dart';
import '../models/job_application_model.dart';
import '../models/job_posting_model.dart';
import '../providers/job_posting_provider.dart';
import 'conversation_screen.dart';

/// Lets a publisher review all applications received for one of their own
/// published jobs and Accept/Reject each candidate.
class ReviewApplicationsScreen extends StatefulWidget {
  const ReviewApplicationsScreen({super.key, required this.job});

  final JobPostingModel job;

  @override
  State<ReviewApplicationsScreen> createState() =>
      _ReviewApplicationsScreenState();
}

class _ReviewApplicationsScreenState extends State<ReviewApplicationsScreen> {
  List<JobApplicationModel> _applications = [];
  bool _loading = true;
  String? _error;
  int? _updatingId;
  String? _updateError;
  late String _jobStatus;
  bool _changingStatus = false;
  String? _statusError;

  @override
  void initState() {
    super.initState();
    _jobStatus = widget.job.status;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apps =
          await context.read<JobPostingProvider>().applicationsForJob(widget.job.id);
      if (!mounted) return;
      setState(() {
        _applications = apps;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load applications. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _setStatus(JobApplicationModel app, String status) async {
    setState(() {
      _updatingId = app.id;
      _updateError = null;
    });

    final ok = await context
        .read<JobPostingProvider>()
        .updateApplicationStatus(
          applicationId: app.id,
          jobPostingId: widget.job.id,
          status: status,
        );

    if (!mounted) return;

    if (ok) {
      // Reflect the new status locally.
      final index = _applications.indexWhere((a) => a.id == app.id);
      if (index != -1) {
        final updated = JobApplicationModel(
          id: app.id,
          jobPostingId: app.jobPostingId,
          jobPostingTitle: app.jobPostingTitle,
          applicantUserId: app.applicantUserId,
          applicantUserName: app.applicantUserName,
          applicantUserEmail: app.applicantUserEmail,
          message: app.message,
          status: status,
          appliedAt: app.appliedAt,
          isActive: app.isActive,
        );
        setState(() => _applications = [..._applications]..[index] = updated);
      }
    } else {
      setState(() {
        _updateError = context.read<JobPostingProvider>().applicationError;
      });
    }
    setState(() => _updatingId = null);
  }

  void _openConversation(JobApplicationModel app) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConversationScreen(
          jobPostingId: widget.job.id,
          jobTitle: widget.job.title,
          otherUserId: app.applicantUserId,
          otherUserName: app.applicantUserName,
        ),
      ),
    );
  }

  /// Opens the review form so the publisher can rate a worker they accepted
  /// for this (completed) job.
  Future<void> _openReview(JobApplicationModel app) async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

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
          reviewedName: app.applicantUserName,
          jobTitle: widget.job.title,
          // Live state so the sheet reflects the submission in progress.
          submitting: reviewProvider.isSubmitting,
          error: reviewProvider.submitError,
          onSubmit: (rating, comment) async {
            final ok = await reviewProvider.submitReview(
              reviewerUserId: reviewerId,
              reviewedUserId: app.applicantUserId,
              jobPostingId: widget.job.id,
              rating: rating,
              comment: comment,
            );
            if (ok && sheetContext.mounted) {
              Navigator.of(sheetContext).pop(true);
            }
          },
        ),
      ),
    );
  }

  /// Transitions this job to a new status (publisher controls the lifecycle).
  Future<void> _changeStatus(String status) async {
    setState(() {
      _changingStatus = true;
      _statusError = null;
    });

    final auth = context.read<AuthProvider>();
    final provider = context.read<JobPostingProvider>();
    final ok = await provider.changeJobStatus(
      jobPostingId: widget.job.id,
      status: status,
      postedByUserId: auth.user?.id ?? 0,
    );

    if (!mounted) return;

    if (ok) {
      setState(() => _jobStatus = status);
    } else {
      setState(() => _statusError = provider.statusError);
    }
    setState(() => _changingStatus = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Applications'),
        backgroundColor: AppConstants.primary,
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Job summary header.
        Container(
          color: AppConstants.primary.withValues(alpha: 0.08),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.job.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_applications.length} '
                '${_applications.length == 1 ? 'application' : 'applications'}',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
        // Job status + lifecycle controls (publisher owns the job).
        _StatusControl(
          status: _jobStatus,
          isChanging: _changingStatus,
          onMarkInProgress: () => _changeStatus('InProgress'),
          onMarkComplete: () => _changeStatus('Completed'),
        ),
        if (_statusError != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _statusError!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        if (_updateError != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _updateError!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        Expanded(
          child: _applications.isEmpty
              ? const _EmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _applications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final app = _applications[index];
                    final canReview = _jobStatus.toLowerCase() == 'completed' &&
                        app.status == 'Accepted';
                    final reviewProvider = context.watch<ReviewProvider>();
                    final reviewedYet = canReview &&
                        reviewProvider.hasReviewed(
                          reviewerUserId: context.read<AuthProvider>().user?.id ?? 0,
                          jobPostingId: widget.job.id,
                        );
                    return _ApplicationTile(
                      application: app,
                      isUpdating: _updatingId == app.id,
                      onAccept: () => _setStatus(app, 'Accepted'),
                      onReject: () => _setStatus(app, 'Rejected'),
                      onMessage: () => _openConversation(app),
                      onReview: canReview ? () => _openReview(app) : null,
                      reviewedYet: reviewedYet,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// An individual application with Accept/Reject actions.
class _ApplicationTile extends StatelessWidget {
  const _ApplicationTile({
    required this.application,
    required this.isUpdating,
    required this.onAccept,
    required this.onReject,
    required this.onMessage,
    this.onReview,
    this.reviewedYet = false,
  });

  final JobApplicationModel application;
  final bool isUpdating;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onMessage;

  /// Optional "Leave a review" action, shown for accepted workers of a
  /// completed job.
  final VoidCallback? onReview;

  /// Whether the publisher already reviewed this worker for this job.
  final bool reviewedYet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = application.status == 'Accepted' ||
        application.status == 'Rejected' ||
        application.status == 'Withdrawn';

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppConstants.primary,
                  child: Text(
                    _initials(application.applicantUserName),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.applicantUserName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        application.applicantUserEmail,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: application.status),
              ],
            ),
            if (application.message?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Text(
                application.message!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (application.appliedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Applied: ${application.appliedAt!.day}.'
                '${application.appliedAt!.month}.${application.appliedAt!.year}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onMessage,
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Message'),
                  ),
                ),
                if (onReview != null && !reviewedYet) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onReview,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                      ),
                      icon: const Icon(Icons.star_outline),
                      label: const Text('Review'),
                    ),
                  ),
                ],
                if (onReview != null && reviewedYet) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check_circle_outline,
                          color: Colors.green),
                      label: const Text('Reviewed'),
                    ),
                  ),
                ],
                if (!done && onReview == null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isUpdating ? null : onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isUpdating ? null : onAccept,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                      ),
                      icon: isUpdating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Accept'),
                    ),
                  ),
                ],
            ],
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0] : '';
    final last =
        parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return '$first$last'.toUpperCase();
  }
}

/// Shows the current job status and lets the publishing owner advance it
/// through the lifecycle: Open -> InProgress -> Completed.
class _StatusControl extends StatelessWidget {
  const _StatusControl({
    required this.status,
    required this.isChanging,
    required this.onMarkInProgress,
    required this.onMarkComplete,
  });

  final String status;
  final bool isChanging;
  final VoidCallback onMarkInProgress;
  final VoidCallback onMarkComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (status) {
      'Completed' => Colors.green,
      'Cancelled' => Colors.grey,
      'InProgress' => Colors.blue,
      _ => Colors.orange,
    };

    return Card(
      elevation: 1,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppConstants.primary),
                const SizedBox(width: 8),
                Text(
                  'Job status',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (status == 'Open')
              _TransitionButton(
                onPressed: isChanging ? null : onMarkInProgress,
                icon: Icons.play_arrow,
                label: 'Mark In Progress',
              )
            else if (status == 'InProgress')
              _TransitionButton(
                onPressed: isChanging ? null : onMarkComplete,
                icon: Icons.verified,
                label: 'Mark Complete',
              )
            else
              Text(
                status == 'Completed'
                    ? 'This job is marked as completed.'
                    : 'This job is no longer active.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }
}

/// A full-width action button used by the status control.
class _TransitionButton extends StatelessWidget {
  const _TransitionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final busy = onPressed == null;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}

/// A small colour-coded status badge.
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
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Empty state when a published job has no applications yet.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text(
          'No applications yet.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        const Text(
          'When someone applies, you can review and respond here.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }
}
