import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../models/user_response_model.dart';
import '../providers/admin_provider.dart';

/// User administration screen.
///
/// Lists/searchable directory of users with an activate/deactivate toggle.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      if (admin.users.isEmpty && !admin.isLoadingUsers) {
        admin.loadUsers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _applyFilter() async {
    final username = _searchController.text.trim();
    await context.read<AdminProvider>().loadUsers(
          username: username.isEmpty ? null : username,
        );
  }

  Future<void> _toggleActive(AdminUserModel user) async {
    final admin = context.read<AdminProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await admin.toggleUserActive(user);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '${user.fullName} is now ${user.isActive ? "inactive" : "active"}.'
              : admin.usersError ?? 'Failed to update user.',
        ),
        backgroundColor: success ? AppConstants.primary : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: AppConstants.primary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _applyFilter(),
              decoration: InputDecoration(
                hintText: 'Search by username',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilter();
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: admin.isLoadingUsers && admin.users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : admin.usersError != null && admin.users.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(admin.usersError!,
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _applyFilter,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : admin.users.isEmpty
                        ? const Center(child: Text('No users found.'))
                        : RefreshIndicator(
                            onRefresh: _applyFilter,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount: admin.users.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final user = admin.users[index];
                                return _UserTile(
                                  user: user,
                                  onToggleActive: () => _toggleActive(user),
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

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.onToggleActive});

  final AdminUserModel user;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roles = user.roles.map((r) => r.name).toList();
    final roleText = roles.isEmpty ? 'No role' : roles.join(', ');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppConstants.primary.withOpacity(0.15),
        child: Text(
          user.fullName.isEmpty ? '?' : user.fullName[0].toUpperCase(),
          style: const TextStyle(
            color: AppConstants.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        user.fullName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('@${user.username} • ${user.email}'),
          Text(
            roleText,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      isThreeLine: true,
      trailing: _ActiveSwitch(
        active: user.isActive,
        onChanged: (_) => onToggleActive(),
      ),
    );
  }
}

class _ActiveSwitch extends StatelessWidget {
  const _ActiveSwitch({required this.active, required this.onChanged});

  final bool active;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              active ? 'Active' : 'Inactive',
              style: TextStyle(
                fontSize: 12,
                color: active ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            Switch(
              value: active,
              onChanged: onChanged,
            ),
          ],
        ),
      ],
      mainAxisAlignment: MainAxisAlignment.center,
    );
  }
}
