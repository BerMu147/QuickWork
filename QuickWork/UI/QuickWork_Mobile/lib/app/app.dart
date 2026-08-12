import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/home/screens/home_screen.dart';
import '../features/jobs/providers/job_posting_provider.dart';
import '../features/jobs/providers/message_provider.dart';
import '../features/lookup/providers/lookup_provider.dart';
import '../features/splash/screens/splash_screen.dart';

/// Root widget of the QuickWork mobile application.
class QuickWorkApp extends StatelessWidget {
  const QuickWorkApp({
    super.key,
    required this.authProvider,
    required this.lookupProvider,
    required this.jobPostingProvider,
  });

  final AuthProvider authProvider;
  final LookupProvider lookupProvider;
  final JobPostingProvider jobPostingProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: lookupProvider),
        ChangeNotifierProvider.value(value: jobPostingProvider),
        // Per-job conversation threads (stock provider, no config needed).
        ChangeNotifierProvider<MessageProvider>(create: (_) => MessageProvider()),
      ],
      child: MaterialApp(
        title: 'QuickWork',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        // First-launch intro (logo), then the home screen.
        home: const SplashScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}

