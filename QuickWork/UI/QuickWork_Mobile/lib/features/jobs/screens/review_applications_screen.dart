import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../models/job_application_model.dart';
import '../models/job_posting_model.dart';
import '../providers/job_posting_provider.dart';

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

  @override
  void initState() {
    super.initState();
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
                    return _ApplicationTile(
                      application: app,
                      isUpdating: _updatingId == app.id,
                      onAccept: () => _setStatus(app, 'Accepted'),
                      onReject: () => _setStatus(app, 'Rejected'),
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
  });

  final JobApplicationModel application;
  final bool isUpdating;
  final VoidCallback onAccept;
  final VoidCallback onReject;

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
            if (!done) ...[
              const SizedBox(height: 12),
              Row(
                children: [
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
                  const SizedBox(width: 10),
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
              ),
            ],
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
