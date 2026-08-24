import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../models/notification_model.dart';
import '../providers/admin_provider.dart';

/// The admin "Notifications" module (Phase 2, Item 3).
///
/// Lets an administrator compose a short announcement (title + message) and
/// send it to **all** users at once (used for downtime / maintenance notes),
/// plus shows the most recent notifications that were sent.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String? _validationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdminProvider>();
      if (provider.notifications.isEmpty && !provider.isLoadingNotifications) {
        provider.loadNotifications();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await context.read<AdminProvider>().loadNotifications();
  }

  Future<void> _send() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    setState(() => _validationError = null);

    if (title.isEmpty || message.isEmpty) {
      setState(() =>
          _validationError = 'Please provide both a title and a message.');
      return;
    }

    final admin = context.read<AdminProvider>();
    final ok = await admin.sendAnnouncement(title: title, message: message);
    if (!mounted) return;

    if (ok) {
      _titleController.clear();
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppConstants.primary,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppConstants.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildComposeCard(admin),
              const SizedBox(height: 24),
              Text(
                'Recent notifications',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (admin.notificationsError != null)
                _ErrorStrip(message: admin.notificationsError!)
              else if (admin.isLoadingNotifications && admin.notifications.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ))
              else if (admin.notifications.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No notifications sent yet.',
                        textAlign: TextAlign.center),
                  ),
                )
              else
                ...admin.notifications.map(
                  (n) => _NotificationCard(
                    notification: n,
                    deleting: admin.isDeletingNotification,
                    onDelete: () async {
                      await context.read<AdminProvider>().deleteNotification(n);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComposeCard(AdminProvider admin) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send announcement to all users',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Used for downtime, maintenance and platform-wide notices.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              enabled: !admin.isSendingNotification,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Scheduled maintenance',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              enabled: !admin.isSendingNotification,
              minLines: 3,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'What users need to know…',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            if (_validationError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _validationError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (admin.sendMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  admin.sendMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (admin.isSendingNotification)
              Column(
                children: [
                  if (admin.sendTotal > 0)
                    LinearProgressIndicator(
                      value: admin.sendTotal > 0
                          ? admin.sendProgress / admin.sendTotal
                          : 0,
                      minHeight: 6,
                    ),
                  const SizedBox(height: 6),
                  Text(
                    'Sending to ${admin.sendProgress} / ${admin.sendTotal} users…',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _send,
                  icon: const Icon(Icons.send),
                  label: const Text('Send to all users'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One row in the received-notification history.
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.deleting,
    required this.onDelete,
  });

  final AdminNotificationModel notification;
  final bool deleting;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final time =
        DateFormat('dd MMM yyyy, HH:mm').format(notification.createdAt.toLocal());

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: AppConstants.primary.withValues(alpha: 0.15),
          child: const Icon(Icons.notifications, color: AppConstants.primary),
        ),
        title: Text(
          notification.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              'User #${notification.userId} · $time',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: 'Delete',
          onPressed: deleting ? null : () async {
            await onDelete();
          },
          icon: const Icon(Icons.delete_outline, color: Colors.red),
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
      width: double.infinity,
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
