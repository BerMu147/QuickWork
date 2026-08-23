import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../admin/screens/dashboard_screen.dart';
import '../../admin/screens/jobs_screen.dart';
import '../../admin/screens/reports_screen.dart';
import '../../admin/screens/reviews_screen.dart';
import '../../admin/screens/users_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';

/// Main shell of the Administrator console.
///
/// Only reachable by authenticated members of the `Administrator` role.
/// Navigation is **responsive**:
/// - Wide screens: a left `NavigationRail`.
/// - Narrow screens: a `BottomNavigationBar`.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const List<Widget> _tabs = [
    DashboardScreen(),
    UsersScreen(),
    JobsScreen(),
    ReviewsScreen(),
    ReportsScreen(),
  ];

  /// Breakpoint above which the left-hand [NavigationRail] is used.
  static const double _railBreakpoint = 600.0;

  bool _useRail() => MediaQuery.of(context).size.width >= _railBreakpoint;

  Future<void> _handleLogout() async {
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final useRail = _useRail();

    // Login gate: the console is only usable by an administrator.
    if (!auth.isAuthenticated || !auth.isAdministrator) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickWork Admin'),
        actions: [
          PopupMenuButton<String>(
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
            child: const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Admin', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left-hand rail on wide screens.
          if (useRail)
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: Text('Users'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.work_outline),
                  selectedIcon: Icon(Icons.work),
                  label: Text('Jobs'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.star_outline),
                  selectedIcon: Icon(Icons.star),
                  label: Text('Reviews'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.assessment_outlined),
                  selectedIcon: Icon(Icons.assessment),
                  label: Text('Reports'),
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
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  label: 'Users',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.work_outline),
                  label: 'Jobs',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.star_outline),
                  label: 'Reviews',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.assessment_outlined),
                  label: 'Reports',
                ),
              ],
            ),
    );
  }
}
