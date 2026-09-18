import 'package:devpilot_app/core/api/api_exception.dart';
import 'package:devpilot_app/core/api/trace_id_interceptor.dart';
import 'package:dio/dio.dart';

/// Converts every failed request into an [ApiException] stored in [DioException.error].
final class ProblemDetailsInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is ApiException) {
      handler.next(err);
      return;
    }
    handler.next(err.copyWith(error: toApiException(err)));
  }

  /// Parses `application/problem+json` (docs/05 §1.2.1). Unparsable responses become
  /// `INTERNAL_ERROR`; failures without a response become `NETWORK_ERROR` or `CLIENT_TIMEOUT`.
  static ApiException toApiException(DioException error) {
    final cause = error.error;
    if (cause is ApiException) {
      return cause;
    }
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => const ApiException(code: ApiErrorCode.clientTimeout),
      DioExceptionType.badResponse ||
      DioExceptionType.badCertificate ||
      DioExceptionType.connectionError ||
      DioExceptionType.cancel ||
      DioExceptionType.unknown => _fromResponse(error.response),
    };
  }

  static ApiException _fromResponse(Response<Object?>? response) {
    if (response == null) {
      return const ApiException(code: ApiErrorCode.networkError);
    }
    final headerTraceId = response.headers.value(TraceIdInterceptor.headerName);
    final body = response.data;
    if (body is Map<String, Object?>) {
      final code = body['code'];
      if (code is String && code.isNotEmpty) {
        return ApiException(
          code: code,
          status: response.statusCode,
          detail: _nonEmptyString(body['detail']),
          traceId: _nonEmptyString(body['traceId']) ?? headerTraceId,
        );
      }
    }
    return ApiException(
      code: ApiErrorCode.internalError,
      status: response.statusCode,
      traceId: headerTraceId,
    );
  }

  static String? _nonEmptyString(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
