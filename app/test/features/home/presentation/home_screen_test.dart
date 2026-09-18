import 'package:devpilot_app/core/auth/token_store.dart';
import 'package:devpilot_app/features/home/data/me_repository.dart';
import 'package:devpilot_app/features/home/data/me_response.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  const email = 'learner@example.com';
  const subject = '5f1c3b1e-8a3d-5b6e-9c2f-1d4e7a9b0c3d';

  // docs/02 A-6: the /me values must reach screen readers, not only the canvas.
  testWidgets('shouldExposeEmailAndSubjectToScreenReadersWhenProfileLoads', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      buildTestApp(
        tokenStore: MemoryTokenStore('stored-access-token'),
        overrides: [
          meRepositoryProvider.overrideWithValue(
            FakeMeRepository(const MeResponse(sub: subject, email: email)),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(RegExp(RegExp.escape(email))), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(RegExp.escape(subject))), findsOneWidget);
    semantics.dispose();
  });
}
