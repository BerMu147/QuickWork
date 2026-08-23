import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../models/user_response_model.dart';
import '../models/user_update_payload.dart';
import '../providers/admin_provider.dart';

/// Administrator detail/edit view for a single user profile.
///
/// Shows the user's full profile (avatar initials, name, username, contact,
/// location, roles, active status) and lets an administrator edit profile
/// fields, assign/remove roles and toggle the active flag.
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, required this.userId});

  final int userId;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdminProvider>();
      if (provider.userDetail?.id != widget.userId) {
        provider.loadUserDetail(widget.userId);
        if (provider.genders.isEmpty) {
          provider.loadLookups();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final user = admin.userDetail;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: AppConstants.primary,
      ),
      body: admin.isLoadingUserDetail && user == null
          ? const Center(child: CircularProgressIndicator())
          : admin.userDetailError != null && user == null
              ? _ErrorState(
                  message: admin.userDetailError!,
                  onRetry: () =>
                      context.read<AdminProvider>().loadUserDetail(widget.userId),
                )
              : user == null
                  ? const Center(child: Text('User not found.'))
                  : _buildProfile(admin, user),
    );
  }

  Widget _buildProfile(AdminProvider admin, AdminUserModel user) {
    return ListView(
      padding: AppConstants.pagePadding,
      children: [
        _ProfileHeader(user: user),
        const SizedBox(height: 16),
        _InfoCard(user: user),
        const SizedBox(height: 16),
        _RolesCard(user: user),
        const SizedBox(height: 16),
        _StatusCard(user: user, admin: admin),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: admin.isSavingUser ? null : () => _openEditSheet(admin),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit profile'),
        ),
      ],
    );
  }

  void _openEditSheet(AdminProvider admin) {
    final user = admin.userDetail!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => _EditProfileSheet(
        user: user,
        onSave: (payload) => _saveProfile(payload),
      ),
    );
  }

  Future<void> _saveProfile(UserUpdatePayload payload) async {
    final admin = context.read<AdminProvider>();

    final saved = await admin.updateUser(
      userId: widget.userId,
      payload: payload,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved ? 'Profile updated successfully.' : 'Failed to update profile.'),
        backgroundColor: saved ? AppConstants.primary : Colors.red,
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AdminUserModel user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppConstants.primary.withValues(alpha: 0.15),
          child: Text(
            user.fullName.isEmpty ? '?' : user.fullName[0].toUpperCase(),
            style: const TextStyle(
              fontSize: 28,
              color: AppConstants.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.fullName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '@${user.username}',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
        _ActiveBadge(active: user.isActive),
      ],
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (active ? Colors.green : Colors.red).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(
          color: active ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.user});

  final AdminUserModel user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.email_outlined, label: 'Email', value: user.email),
            const Divider(height: 20),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: user.phoneNumber ?? '—',
            ),
            const Divider(height: 20),
            _InfoRow(icon: Icons.location_city_outlined, label: 'City', value: user.cityName),
            const Divider(height: 20),
            _InfoRow(icon: Icons.person_outline, label: 'Gender', value: user.genderName),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppConstants.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label: ${value.isNotEmpty ? value : '—'}',
                style: TextStyle(fontSize: 15, color: Colors.grey[800]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RolesCard extends StatelessWidget {
  const _RolesCard({required this.user});

  final AdminUserModel user;

  @override
  Widget build(BuildContext context) {
    final roles = user.roles.map((r) => r.name).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assigned roles',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (roles.isEmpty)
              const Text(
                'The user has no roles assigned.',
                style: TextStyle(color: Colors.grey),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: roles
                    .map(
                      (r) => Chip(
                        label: Text(r),
                        backgroundColor:
                            AppConstants.primary.withValues(alpha: 0.1),
                        labelStyle: const TextStyle(
                          color: AppConstants.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.user, required this.admin});

  final AdminUserModel user;
  final AdminProvider admin;

  @override
  Widget build(BuildContext context) {
    if (user.bio == null || user.bio!.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bio',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(user.bio!, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// Bottom-sheet edit form. Collects the fields locally and calls [onSave]
/// (which wires to the provider) when the user taps "Save".
class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.user, required this.onSave});

  final AdminUserModel user;
  final Future<void> Function(UserUpdatePayload payload) onSave;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;
  late int _genderId;
  late int _cityId;
  late bool _isActive;
  late List<int> _selectedRoleIds;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _firstNameController = TextEditingController(text: user.firstName);
    _lastNameController = TextEditingController(text: user.lastName);
    _emailController = TextEditingController(text: user.email);
    _phoneController = TextEditingController(text: user.phoneNumber ?? '');
    _bioController = TextEditingController(text: user.bio ?? '');
    _genderId = user.genderId;
    _cityId = user.cityId;
    _isActive = user.isActive;
    _selectedRoleIds = (user.roles.map((r) => r.id).toList());
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final payload = UserUpdatePayload(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      username: widget.user.username,
      phoneNumber: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      bio: _bioController.text.trim().isEmpty
          ? null
          : _bioController.text.trim(),
      genderId: _genderId,
      cityId: _cityId,
      isActive: _isActive,
      roleIds: _selectedRoleIds,
    );

    Navigator.of(context).pop();
    widget.onSave(payload);
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Text(
                  'Edit user profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'First name required.'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Last name required.'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Email required.';
                  if (!value.contains('@')) return 'Enter a valid email.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Bio (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              if (admin.isLoadingLookups && admin.genders.isEmpty)
                const Center(child: CircularProgressIndicator())
              else ...[
                DropdownButtonFormField<int>(
                  value: admin.genders.any((g) => g.id == _genderId)
                      ? _genderId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: admin.genders
                      .map((g) =>
                          DropdownMenuItem<int>(value: g.id, child: Text(g.name)))
                      .toList(),
                  onChanged: admin.genders.isEmpty
                      ? null
                      : (v) => setState(() => _genderId = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: admin.cities.any((c) => c.id == _cityId) ? _cityId : null,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  items: admin.cities
                      .map((c) =>
                          DropdownMenuItem<int>(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: admin.cities.isEmpty
                      ? null
                      : (v) => setState(() => _cityId = v!),
                ),
              ],
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Account active'),
                subtitle: const Text('Inactive users cannot use the app'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 8),
              Text(
                'Assign roles',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (admin.isLoadingLookups && admin.allRoles.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: admin.allRoles
                      .map(
                        (role) => FilterChip(
                          label: Text(role.name),
                          selected: _selectedRoleIds.contains(role.id),
                          onSelected: (sel) {
                            setState(() {
                              if (sel) {
                                _selectedRoleIds.add(role.id);
                              } else {
                                _selectedRoleIds.remove(role.id);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
