import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/home/screens/home_screen.dart';

/// Root widget of the QuickWork mobile application.
class QuickWorkApp extends StatelessWidget {
  const QuickWorkApp({super.key, required this.authProvider});

  final AuthProvider authProvider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: authProvider,
      child: MaterialApp(
      title: 'QuickWork',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
        // The home screen is reachable by everyone, logged in or not.
        home: const HomeScreen(),
        ),
    );
  }
}

