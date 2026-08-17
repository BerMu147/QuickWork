import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/skill_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/profile_screen.dart';
import '../../jobs/providers/job_posting_provider.dart';
import '../../jobs/providers/message_provider.dart';
import '../../jobs/screens/jobs_screen.dart';
import '../../jobs/screens/my_jobs_screen.dart';
import '../../jobs/screens/publish_job_screen.dart';
import '../../reviews/providers/review_provider.dart';

/// Main shell of the app. Reachable by everyone (no login required).
///
/// Guests can browse jobs freely, but publishing/applying requires an account.
///
/// Navigation is **responsive**:
/// - Wide screens (desktop/tablet landscape): a `NavigationRail` on the left
///   with a "Publish" button docked to it.
/// - Narrow screens (phones): a `BottomNavigationBar` plus a floating
///   "Publish" action button.
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
    ProfileScreen(),
  ];

  /// Breakpoint above which the left-hand [NavigationRail] is used.
  static const double _railBreakpoint = 600.0;

  bool _useRail() => MediaQuery.of(context).size.width >= _railBreakpoint;

  Future<void> _handleLogout() async {
    // Clear per-user provider state before logging out so one account's
    // skills/jobs/reviews/messages never leak into the next account.
    context.read<SkillProvider>().clear();
    context.read<JobPostingProvider>().clear();
    context.read<ReviewProvider>().clear();
    context.read<MessageProvider>().clear();
    await context.read<AuthProvider>().logout();
  }

  void _openPublishJob() {
    Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PublishJobScreen()),
    );
  }

  void _openLogin() {
    Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Widget _accountAction(AuthProvider auth) {
    if (auth.isAuthenticated) {
      return PopupMenuButton<String>(
        tooltip: 'Account',
        offset: const Offset(0, 50),
        onSelected: (value) async {
          if (value == 'logout') await _handleLogout();
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
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
      );
    }
    return IconButton(
      icon: const Icon(Icons.login),
      tooltip: 'Log in',
      onPressed: _openLogin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final useRail = _useRail();

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickWork'),
        actions: [_accountAction(auth)],
      ),
      body: Row(
        children: [
          // Left-hand rail on wide screens.
          if (useRail)
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Publish a job',
                  onPressed: auth.isAuthenticated ? _openPublishJob : _openLogin,
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.work_outline),
                  selectedIcon: Icon(Icons.work),
                  label: Text('Jobs'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.list_alt_outlined),
                  selectedIcon: Icon(Icons.list_alt),
                  label: Text('My Jobs'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('Profile'),
                ),
              ],
            ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _tabs,
            ),
          ),
        ],
      ),
      bottomNavigationBar: useRail
          ? null
          : BottomNavigationBar(
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
      // A "+" Publish button for narrow screens, shown to logged-in users on
      // the Jobs tab. (Wide screens use the rail's "add" icon instead.)
      floatingActionButton: !useRail && auth.isAuthenticated && _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _openPublishJob,
              icon: const Icon(Icons.add),
              label: const Text('Publish'),
            )
          : null,
    );
  }
}
