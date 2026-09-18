import 'package:devpilot_app/app/app.dart';
import 'package:devpilot_app/app/router.dart';
import 'package:devpilot_app/core/auth/auth_repository.dart';
import 'package:devpilot_app/core/auth/dev_token_response.dart';
import 'package:devpilot_app/core/auth/token_store.dart';
import 'package:devpilot_app/features/home/data/me_repository.dart';
import 'package:devpilot_app/features/home/data/me_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../support/test_app.dart';

void main() {
  const email = 'learner@example.com';
  const subject = '5f1c3b1e-8a3d-5b6e-9c2f-1d4e7a9b0c3d';
  const me = MeResponse(sub: subject, email: email);

  testWidgets('shouldShowMeEmailOnHomeWhenLoginSucceeds', (tester) async {
    final tokenStore = MemoryTokenStore();
    final authRepository = MockAuthRepository();
    when(() => authRepository.issueDevToken(email)).thenAnswer(
      (_) async => DevTokenResponse(
        accessToken: 'test-access-token',
        tokenType: 'Bearer',
        expiresAt: DateTime.utc(2026, 10, 18, 9),
      ),
    );
    await tester.pumpWidget(
      buildTestApp(
        tokenStore: tokenStore,
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          meRepositoryProvider.overrideWithValue(FakeMeRepository(me)),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(emailFieldKey), email);
    await tester.pump();
    await tester.tap(find.byKey(submitButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(emailFieldKey), findsNothing);
    expect(find.text(email), findsOneWidget);
    expect(find.text(subject), findsOneWidget);
    expect(tokenStore.read(), 'test-access-token');
  });

  testWidgets('shouldReturnToLoginAndClearTokenWhenLogoutIsTapped', (tester) async {
    final tokenStore = MemoryTokenStore('stored-access-token');
    await tester.pumpWidget(
      buildTestApp(
        tokenStore: tokenStore,
        overrides: [meRepositoryProvider.overrideWithValue(FakeMeRepository(me))],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(email), findsOneWidget);

    await tester.tap(find.byKey(logoutButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(emailFieldKey), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '로그인'), findsOneWidget);
    expect(tokenStore.read(), isNull);
  });

  testWidgets('shouldShowNotFoundScreenWhenRouteIsUnknown', (tester) async {
    await tester.pumpWidget(buildTestApp(tokenStore: MemoryTokenStore()));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(DevPilotApp)));

    container.read(routerProvider).go('/does-not-exist');
    await tester.pumpAndSettle();
    expect(find.text('페이지를 찾을 수 없어요'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '처음으로'));
    await tester.pumpAndSettle();
    expect(find.byKey(emailFieldKey), findsOneWidget);
  });
}
