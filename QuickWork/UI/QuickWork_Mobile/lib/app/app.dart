import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Root widget of the QuickWork mobile application.
class QuickWorkApp extends StatelessWidget {
  const QuickWorkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickWork',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const Scaffold(
        body: Center(
          child: Text('QuickWork'),
        ),
      ),
    );
  }
}
