import 'package:dio/dio.dart';

/// Thrown when a network/HTTP request fails.
///
/// Carries a user-friendly [message] plus optional [statusCode] and
/// [details] so callers (UI/Providers) can react appropriately.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.details,
  });

  final String message;
  final int? statusCode;
  final dynamic details;

  @override
  String toString() => message;

  /// Builds an [ApiException] from a Dio error, translating common
  /// conditions into clear messages.
  factory ApiException.fromDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(message: 'Connection timed out. '
            'Please check your network connection and try again.');

      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'Could not connect to the server. '
              'Please check your network connection.',
        );

      case DioExceptionType.badCertificate:
        return const ApiException(
          message: 'The server certificate could not be verified.',
        );

      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final data = e.response?.data;
        var msg = 'Unexpected server error. Please try again.';

        // Try to surface a backend-supplied message.
        if (data is Map) {
          // Common shape: { "message": "..." }
          if (data['message'] != null) {
            msg = data['message'].toString();
          }
          // ASP.NET filter shape: { "errors": { "key": ["msg", ...] } }
          else {
            final errors = data['errors'];
            if (errors is Map && errors.isNotEmpty) {
              final first = errors.values.first;
              if (first is List && first.isNotEmpty) {
                msg = first.first.toString();
              }
            }
          }
        } else if (status == 401) {
          msg = 'Incorrect username or password.';
        } else if (status == 403) {
          msg = 'You do not have permission to do that.';
        } else if (status == 404) {
          msg = 'The requested resource was not found.';
        } else if (status == 500) {
          msg = 'The server encountered an error. Please try again later.';
        }

        return ApiException(message: msg, statusCode: status, details: data);

      case DioExceptionType.cancel:
        return const ApiException(message: 'The request was cancelled.');

      case DioExceptionType.unknown:
        // e.error often holds the real underlying exception (e.g. a
        // SocketException or HandshakeException) for unknown failures.
        final underlying = e.error;
        return ApiException(
          message: underlying?.toString() ?? (e.message ?? 'An unknown error occurred.'),
        );
    }
  }
}
