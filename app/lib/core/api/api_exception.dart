/// Error codes the client branches on (docs/05 §1.3, docs/02 §5.1).
///
/// Server codes arrive in the Problem Details `code` field. `NETWORK_ERROR` and `CLIENT_TIMEOUT` are
/// produced by the client only.
abstract final class ApiErrorCode {
  static const authenticationRequired = 'AUTHENTICATION_REQUIRED';
  static const userNotAllowed = 'USER_NOT_ALLOWED';
  static const rateLimited = 'RATE_LIMITED';
  static const internalError = 'INTERNAL_ERROR';
  static const networkError = 'NETWORK_ERROR';
  static const clientTimeout = 'CLIENT_TIMEOUT';
}

/// Failure of an API call, parsed from an RFC 9457 Problem Details body.
///
/// Callers branch on [code] only, never on [status] or [detail] (docs/05 §1.2.1).
final class ApiException implements Exception {
  const ApiException({required this.code, this.status, this.detail, this.traceId});

  final String code;

  /// HTTP status. Null for client-side failures that never reached the server.
  final int? status;

  /// User-facing Korean sentence from the server, if any.
  final String? detail;

  /// 32 hex chars. Shown only in the collapsed report section of error views.
  final String? traceId;

  @override
  String toString() => 'ApiException(code: $code, status: $status, traceId: $traceId)';
}
