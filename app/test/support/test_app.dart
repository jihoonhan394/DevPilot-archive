import 'package:devpilot_app/app/app.dart';
import 'package:devpilot_app/core/auth/auth_repository.dart';
import 'package:devpilot_app/core/auth/token_store.dart';
import 'package:devpilot_app/core/auth/token_store_provider.dart';
import 'package:devpilot_app/core/config/app_config.dart';
import 'package:devpilot_app/features/home/data/me_repository.dart';
import 'package:devpilot_app/features/home/data/me_response.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:mocktail/mocktail.dart';

const testAppConfig = AppConfig(authMode: AuthMode.dev, apiBaseUrl: 'http://localhost:8080');

const emailFieldKey = Key('login.emailField');
const submitButtonKey = Key('login.submitButton');
const logoutButtonKey = Key('home.logoutButton');

/// The whole app with in-memory session storage. Repositories are replaced through [overrides];
/// nothing reaches the network.
Widget buildTestApp({required TokenStore tokenStore, List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(testAppConfig),
      tokenStoreProvider.overrideWithValue(tokenStore),
      ...overrides,
    ],
    retry: (retryCount, error) => null,
    child: const DevPilotApp(),
  );
}

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeMeRepository implements MeRepository {
  FakeMeRepository(this._response);

  final MeResponse _response;

  @override
  Future<MeResponse> fetchMe() async => _response;
}
