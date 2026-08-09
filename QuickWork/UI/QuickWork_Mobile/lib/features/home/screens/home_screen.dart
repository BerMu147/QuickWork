import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../jobs/screens/jobs_screen.dart';
import '../../jobs/screens/my_jobs_screen.dart';
import '../../jobs/screens/publish_job_screen.dart';



/// Main shell of the app. Reachable by everyone — no login required.
///
/// Guests can browse jobs freely, but publishing/applying requires an account.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

    static const List<Widget> _tabs = [
    JobsScreen(),
    MyJobsScreen(),
    _PlaceholderTab(icon: Icons.person_outline, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickWork'),
        actions: [
          if (auth.isAuthenticated)
            PopupMenuButton<String>(
              tooltip: 'Account',
              offset: const Offset(0, 50),
              onSelected: (value) async {
                if (value == 'logout') {
                  await context.read<AuthProvider>().logout();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                  auth.user?.fullName ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                      const SizedBox(height: 2),
                      Text(
                        auth.user?.email ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
              ),
                      ),
        ],
      ),
      ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text('Log out'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  children: [
                    const Icon(Icons.account_circle, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      auth.user?.fullName ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
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
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFF129ACA),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            label: 'My Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
                    ),
        ],
      ),
      // A "+" button to publish a job, only shown to logged-in users on the
      // Jobs tab. Publishing is account-gated (like checking out in a shop).
      floatingActionButton:
          auth.isAuthenticated && _currentIndex == 0
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const PublishJobScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Publish'),
                )
              : null,
    );
  }
}

/// A simple placeholder tab used until its real content is built.
class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            '$label coming soon',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

