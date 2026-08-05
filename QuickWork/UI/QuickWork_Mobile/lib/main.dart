import 'package:flutter/material.dart';
import 'package:quickwork_mobile/core/api/api_client.dart';
import 'package:quickwork_mobile/features/auth/providers/auth_provider.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prepare the HTTP client (adds the bearer-token interceptor and the
  // self-signed cert acceptance used during development).
  ApiClient.instance.init();
  // Wire up the auth state and restore any saved session before we build UI.
  final authProvider = AuthProvider();
  await authProvider.restoreSession();

  runApp(QuickWorkApp(authProvider: authProvider));
}

