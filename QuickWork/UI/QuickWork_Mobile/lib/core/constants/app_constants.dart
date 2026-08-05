import 'package:flutter/material.dart';

/// Central place for global application constants.
class AppConstants {
  AppConstants._();

  // ---------------------------------------------------------------------------
  // Brand color palette (as per the design brief)
  // ---------------------------------------------------------------------------
  static const Color primary = Color(0xFF129ACA); // teal blue
  static const Color secondary = Color(0xFF33BCDE); // lighter cyan
  static const Color tertiary = Color(0xFF6DD6EC); // light cyan
  static const Color quaternary = Color(0xFF9AEFF2); // very light cyan
  static const Color background = Color(0xFFFAEFEF); // off-white / cream

  // ---------------------------------------------------------------------------
  // API configuration
  // ---------------------------------------------------------------------------
  /// Base URL of the QuickWork backend.
  ///
  /// The backend serves HTTPS on this port with a self-signed development
  /// certificate. The correct host depends on where the app runs:
  /// - Physical Android device : use your computer's LAN IP (192.168.0.15)
  /// - Android emulator         : https://10.0.2.2:7074
  /// - Windows / Web            : https://localhost:7074
  ///
  /// NOTE: A `badCertificateCallback` is configured in `ApiClient` to accept
  /// the self-signed dev cert. This must be removed for production.
  static const String apiBaseUrl = 'https://192.168.0.15:7074';

  // ---------------------------------------------------------------------------
  // Auth / persistence keys
  // ---------------------------------------------------------------------------
  static const String authTokenKey = 'auth_token';
  static const String authUserKey = 'auth_user';

  // ---------------------------------------------------------------------------
  // Generic UI
  // ---------------------------------------------------------------------------
  static const double defaultRadius = 12.0;
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: 20.0,
    vertical: 16.0,
  );
}

