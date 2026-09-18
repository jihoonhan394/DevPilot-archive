import 'package:devpilot_app/core/api/api_exception.dart';
import 'package:devpilot_app/core/api/auth_token_interceptor.dart';
import 'package:devpilot_app/core/api/dio_provider.dart';
import 'package:devpilot_app/core/api/problem_details_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// JSON calls against `/api/v1`. Every failure surfaces as an [ApiException].
final class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  /// GET [path] (relative to `/api/v1`) and return the JSON object body.
  Future<Map<String, Object?>> getJson(String path) => _send(() => _dio.get<Object?>(path));

  /// POST [body] to [path]. [authenticated] is false only for endpoints outside JWT auth.
  Future<Map<String, Object?>> postJson(
    String path, {
    required Map<String, Object?> body,
    bool authenticated = true,
  }) => _send(
    () => _dio.post<Object?>(
      path,
      data: body,
      options: Options(extra: {AuthTokenInterceptor.skipAuthKey: !authenticated}),
    ),
  );

  Future<Map<String, Object?>> _send(Future<Response<Object?>> Function() request) async {
    final Response<Object?> response;
    try {
      response = await request();
    } on DioException catch (error, stackTrace) {
      Error.throwWithStackTrace(ProblemDetailsInterceptor.toApiException(error), stackTrace);
    }
    final body = response.data;
    if (body is Map<String, Object?>) {
      return body;
    }
    throw ApiException(code: ApiErrorCode.internalError, status: response.statusCode);
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(dioProvider)));
