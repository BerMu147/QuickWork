import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import 'edit_profile_screen.dart';

/// The "Profile" tab — shows the logged-in user's information.
///
/// Login-gated: a guest opening this tab is prompted to log in.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    if (!auth.isAuthenticated) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 56, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'Log in to see your profile.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: Colors.grey[700]),
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

    final user = auth.user!;

    return ListView(
      padding: AppConstants.pagePadding,
      children: [
        const SizedBox(height: 16),
        // Avatar + name header.
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: AppConstants.primary,
            child: Text(
              _initials(user.firstName, user.lastName),
              style: const TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            user.fullName,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppConstants.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Center(
          child: Text(
            '@${user.username}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Colors.grey[600]),
          ),
        ),
        const SizedBox(height: 24),

        // User details card.
        Card(
          elevation: 1,
          child: Column(
            children: [
              _InfoRow(icon: Icons.email_outlined, label: 'Email', value: user.email),
              _divider(),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: user.phoneNumber?.isNotEmpty == true
                    ? user.phoneNumber!
                    : '—',
              ),
              _divider(),
              _InfoRow(
                icon: Icons.location_city_outlined,
                label: 'City',
                value: user.cityName,
              ),
              _divider(),
              _InfoRow(
                icon: Icons.person_outline,
                label: 'Gender',
                value: user.genderName,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Edit profile button.
        ElevatedButton.icon(
          onPressed: () async {
            await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            );
          },
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit profile'),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  String _initials(String firstName, String lastName) {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  Widget _divider() => const Divider(height: 1);
}

/// A single info row (icon + label + value).
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppConstants.primary),
      title: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16)),
    );
  }
}
