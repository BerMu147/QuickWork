import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';

/// Intro / splash screen shown on first launch to give a first impression.
///
/// On later launches the app goes straight to the home screen (tracked via a
/// persisted `has_seen_intro` flag). Uses only the branded logo — no video.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String _seenKey = 'has_seen_intro';
  static const Duration _fadeDuration = Duration(milliseconds: 450);

  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fade the logo in smoothly.
      setState(() => _visible = true);
    });
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_seenKey) ?? false;

    if (!mounted) return;

    // Give the branded logo a brief moment regardless of whether it's the
    // first launch or not, then hand off to the home screen.
    final wait = seen ? const Duration(milliseconds: 1300) : _fadeDuration;
    await Future.delayed(wait);

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');

    // Remember the intro was shown so the splash only lingers on first launch.
    if (!seen) {
      await prefs.setBool(_seenKey, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primary,
      body: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: _fadeDuration,
        curve: Curves.easeIn,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/splash_logo.png',
                width: 180,
                height: 180,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.work,
                  size: 120,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'QuickWork',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

