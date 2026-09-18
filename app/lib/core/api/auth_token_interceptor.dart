import 'package:devpilot_app/core/api/api_exception.dart';
import 'package:devpilot_app/core/api/problem_details_interceptor.dart';
import 'package:dio/dio.dart';

/// Sends `Authorization: Bearer <token>` and ends the session on `AUTHENTICATION_REQUIRED`.
///
/// devtoken mode has no refresh token, so a 401 goes straight to the login screen (docs/07 §3.4).
final class AuthTokenInterceptor extends Interceptor {
  AuthTokenInterceptor({required this._readAccessToken, required this._onSessionExpired});

  /// `RequestOptions.extra` flag for endpoints outside authentication (`POST /dev/token`).
  static const skipAuthKey = 'devpilot.skipAuth';

  final String? Function() _readAccessToken;
  final void Function() _onSessionExpired;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_skipsAuth(options)) {
      handler.next(options);
      return;
    }
    final accessToken = _readAccessToken();
    if (accessToken == null) {
      // Without a session the request would only produce a 401, so it is not sent at all.
      handler.reject(
        DioException(
          requestOptions: options,
          error: const ApiException(code: ApiErrorCode.authenticationRequired),
        ),
      );
      return;
    }
    options.headers['Authorization'] = 'Bearer $accessToken';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final code = ProblemDetailsInterceptor.toApiException(err).code;
    if (!_skipsAuth(err.requestOptions) && code == ApiErrorCode.authenticationRequired) {
      _onSessionExpired();
    }
    handler.next(err);
  }

  static bool _skipsAuth(RequestOptions options) {
    final Object? flag = options.extra[skipAuthKey];
    return flag == true;
  }
}
