import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../models/admin_job_application_model.dart';
import '../providers/admin_provider.dart';

/// Job applications / worker-requests oversight screen.
///
/// Lets an administrator browse requests made by workers for jobs, filter by
/// status, and delete a request as a moderation action. The publisher
/// Accept/Reject flow stays user-facing.
class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  String? _selectedStatus;

  static const List<String> _statuses = [
    'Pending',
    'Accepted',
    'Rejected',
    'Withdrawn',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      if (admin.jobApplications.isEmpty && !admin.isLoadingJobApplications) {
        admin.loadJobApplications();
      }
    });
  }

  Future<void> _load() async {
    await context
        .read<AdminProvider>()
        .loadJobApplications(status: _selectedStatus);
  }

  Future<void> _confirmAndDelete(AdminJobApplicationModel application) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete request'),
        content: Text(
          'Delete the request by "${application.applicantUserName}" for '
          '"${application.jobPostingTitle}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final admin = context.read<AdminProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await admin.deleteJobApplication(application);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Request deleted.' : 'Failed to delete request.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Requests'),
        backgroundColor: AppConstants.primary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in _statuses)
                  ChoiceChip(
                    label: Text(status),
                    selected: _selectedStatus == status,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = selected ? status : null;
                      });
                      _load();
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: admin.isLoadingJobApplications &&
                    admin.jobApplications.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : admin.jobApplicationsError != null &&
                        admin.jobApplications.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                admin.jobApplicationsError!,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _load,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : admin.jobApplications.isEmpty
                        ? const Center(child: Text('No requests found.'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount: admin.jobApplications.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final application =
                                    admin.jobApplications[index];
                                return _RequestTile(
                                  application: application,
                                  onDelete: () =>
                                      _confirmAndDelete(application),
                                  deleting: admin.isDeletingJobApplication,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.application,
    required this.onDelete,
    required this.deleting,
  });

  final AdminJobApplicationModel application;
  final VoidCallback onDelete;
  final bool deleting;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(application.status);
    final appliedDate = DateFormat.yMMMd().format(application.appliedAt);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(application.applicantUserName),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('For: ${application.jobPostingTitle}'),
            Text(
              'Applied: $appliedDate',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (application.message != null &&
                application.message!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(application.message!),
            ],
          ],
        ),
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              application.status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Delete request',
            onPressed: deleting ? null : onDelete,
            icon: Icon(
              Icons.delete_outline,
              color: deleting ? Colors.grey : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'accepted':
        return const Color(0xFF4CAF50);
      case 'rejected':
        return Colors.red;
      case 'withdrawn':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }
}
