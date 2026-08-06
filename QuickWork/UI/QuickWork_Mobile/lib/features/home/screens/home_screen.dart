import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';

/// Main screen of the app. Reachable by everyone — no login required.
///
/// Guests can browse content, but publishing/applying requires an account.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickWork'),
        actions: [
          if (auth.isAuthenticated)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  auth.user?.fullName ?? '',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.login),
              tooltip: 'Log in',
              onPressed: () async {
                await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
        ],
      ),
      body: const Center(
        child: Text('Browse jobs coming soon'),
      ),
    );
  }
}

