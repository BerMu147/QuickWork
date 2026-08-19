import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../constants/app_constants.dart';

/// Singleton HTTP client used across the whole app.
///
/// Configured with:
/// - the backend base URL
/// - a JSON content type
/// - an interceptor that auto-attaches the saved JWT bearer token
///   to every authenticated request
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  /// The JWT token to attach to requests, if any.
  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Clean HTTP client for all API calls.
  Dio get dio => _dio;

  bool _initialized = false;
  /// Configures [dio] to attach the bearer token and centralise self-signed
  /// cert handling. Idempotent — safe to call more than once.
  void init() {
    if (_initialized) return;
    _initialized = true;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _authToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    // During development the backend uses a self-signed certificate.
    // Accept any certificate so we can reach the local server.
    // DO NOT ship this in production — use a properly chained, trusted
    // certificate there instead.
    final adapter = _dio.httpClientAdapter;
    if (adapter is IOHttpClientAdapter) {
      adapter.createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }
  }
}
