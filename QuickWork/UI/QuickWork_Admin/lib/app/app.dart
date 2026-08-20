import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../features/admin/providers/admin_provider.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/home/screens/home_screen.dart';

/// Root widget of the QuickWork administrator console.
class QuickWorkAdminApp extends StatelessWidget {
  const QuickWorkAdminApp({
    super.key,
    required this.authProvider,
    required this.adminProvider,
  });

  final AuthProvider authProvider;
  final AdminProvider adminProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: adminProvider),
      ],
      child: MaterialApp(
        title: 'QuickWork Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomeScreen(),
      ),
    );
  }
}
