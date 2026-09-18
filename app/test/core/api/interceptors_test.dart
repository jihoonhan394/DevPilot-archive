import 'dart:convert';
import 'dart:typed_data';

import 'package:devpilot_app/core/api/api_client.dart';
import 'package:devpilot_app/core/api/api_exception.dart';
import 'package:devpilot_app/core/api/dio_provider.dart';
import 'package:devpilot_app/core/auth/auth_controller.dart';
import 'package:devpilot_app/core/auth/token_store.dart';
import 'package:devpilot_app/core/auth/token_store_provider.dart';
import 'package:devpilot_app/core/config/app_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

typedef _Responder = Future<ResponseBody> Function(RequestOptions options);

/// Records requests and answers them without a network.
final class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._respond);

  final _Responder _respond;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return _respond(options);
  }

  @override
  void close({bool force = false}) {}
}

Future<ResponseBody> _json(int status, Map<String, Object?> body, {String? contentType}) async =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [contentType ?? Headers.jsonContentType],
      },
    );

Future<ResponseBody> _problem(int status, String code, {String? detail}) => _json(status, {
  'type': 'urn:devpilot:problem:test',
  'title': 'Test',
  'status': status,
  'detail': detail,
  'instance': '/api/v1/me',
  'code': code,
  'traceId': '4bf92f3577b34da6a3ce929d0e0e4736',
  'errors': <Object?>[],
}, contentType: 'application/problem+json');

void main() {
  late MemoryTokenStore tokenStore;
  late _FakeAdapter adapter;
  late ProviderContainer container;

  void setUpClient({String? storedToken, required _Responder respond}) {
    tokenStore = MemoryTokenStore(storedToken);
    adapter = _FakeAdapter(respond);
    container = ProviderContainer.test(
      overrides: [
        appConfigProvider.overrideWithValue(testAppConfig),
        tokenStoreProvider.overrideWithValue(tokenStore),
      ],
      retry: (retryCount, error) => null,
    );
    container.read(dioProvider).httpClientAdapter = adapter;
  }

  ApiClient apiClient() => container.read(apiClientProvider);

  Matcher throwsApiException(String code) =>
      throwsA(isA<ApiException>().having((error) => error.code, 'code', code));

  test('shouldSendBearerTokenAndTraceIdWhenSignedIn', () async {
    setUpClient(storedToken: 'access-token', respond: (_) => _json(200, {'sub': 'subject'}));

    final body = await apiClient().getJson('/me');

    expect(body, {'sub': 'subject'});
    final request = adapter.requests.single;
    expect(request.uri.toString(), 'http://localhost:8080/api/v1/me');
    expect(request.headers['Authorization'], 'Bearer access-token');
    expect(request.headers['X-Trace-Id'], matches(RegExp(r'^[0-9a-f]{32}$')));
  });

  test('shouldPostDevTokenWithoutAuthorizationWhenUnauthenticated', () async {
    setUpClient(respond: (_) => _json(200, {'accessToken': 'issued'}));

    await apiClient().postJson(
      '/dev/token',
      body: {'email': 'learner@example.com'},
      authenticated: false,
    );

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.uri.path, '/api/v1/dev/token');
    expect(request.headers.containsKey('Authorization'), isFalse);
    expect(request.data, {'email': 'learner@example.com'});
  });

  test('shouldThrowApiExceptionWithProblemDetailFieldsWhenServerRejects', () async {
    setUpClient(respond: (_) => _problem(403, 'USER_NOT_ALLOWED', detail: '허용되지 않음'));

    final future = apiClient().postJson(
      '/dev/token',
      body: {'email': 'outsider@example.com'},
      authenticated: false,
    );

    await expectLater(
      future,
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', ApiErrorCode.userNotAllowed)
            .having((error) => error.status, 'status', 403)
            .having((error) => error.detail, 'detail', '허용되지 않음')
            .having((error) => error.traceId, 'traceId', '4bf92f3577b34da6a3ce929d0e0e4736'),
      ),
    );
  });

  test('shouldExpireSessionWhenServerAnswersAuthenticationRequired', () async {
    setUpClient(
      storedToken: 'expired-token',
      respond: (_) => _problem(401, 'AUTHENTICATION_REQUIRED'),
    );

    await expectLater(
      apiClient().getJson('/me'),
      throwsApiException(ApiErrorCode.authenticationRequired),
    );

    final authState = container.read(authStateProvider);
    expect(authState, isA<SignedOut>());
    expect((authState as SignedOut).reason, SignOutReason.expired);
    expect(tokenStore.read(), isNull);
  });

  test('shouldNotCallServerWhenAuthenticatedRequestHasNoSession', () async {
    setUpClient(respond: (_) => _json(200, {}));

    await expectLater(
      apiClient().getJson('/me'),
      throwsApiException(ApiErrorCode.authenticationRequired),
    );

    expect(adapter.requests, isEmpty);
    expect((container.read(authStateProvider) as SignedOut).reason, isNull);
  });

  test('shouldMapConnectionFailureToNetworkError', () async {
    setUpClient(
      storedToken: 'access-token',
      respond: (options) =>
          Future.error(DioException.connectionError(requestOptions: options, reason: 'offline')),
    );

    await expectLater(apiClient().getJson('/me'), throwsApiException(ApiErrorCode.networkError));
  });

  test('shouldMapNonProblemErrorResponseToInternalError', () async {
    setUpClient(
      storedToken: 'access-token',
      respond: (_) async => ResponseBody.fromString(
        '<html>bad gateway</html>',
        502,
        headers: {
          Headers.contentTypeHeader: ['text/html'],
        },
      ),
    );

    await expectLater(
      apiClient().getJson('/me'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', ApiErrorCode.internalError)
            .having((error) => error.status, 'status', 502),
      ),
    );
  });
}
