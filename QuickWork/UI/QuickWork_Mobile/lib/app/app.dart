import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/home/screens/home_screen.dart';
import '../features/lookup/providers/lookup_provider.dart';

/// Root widget of the QuickWork mobile application.
class QuickWorkApp extends StatelessWidget {
  const QuickWorkApp({
    super.key,
    required this.authProvider,
    required this.lookupProvider,
  });
  final AuthProvider authProvider;
  final LookupProvider lookupProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: lookupProvider),
      ],
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

