import 'package:devpilot_app/app/router.dart';
import 'package:devpilot_app/core/auth/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const signedIn = SignedIn('access-token');
  const signedOut = SignedOut();

  String? redirect(AuthState authState, String location) =>
      redirectForAuth(authState, Uri.parse(location));

  test('shouldSendSignedOutUserToLoginWhenRouteRequiresAuth', () {
    expect(redirect(signedOut, '/'), '/login');
  });

  test('shouldAddExpiredReasonWhenSessionExpired', () {
    expect(redirect(const SignedOut(reason: SignOutReason.expired), '/'), '/login?reason=expired');
  });

  test('shouldStayWhenSignedOutUserIsOnLoginOrUnknownRoute', () {
    expect(redirect(signedOut, '/login'), isNull);
    expect(redirect(signedOut, '/does-not-exist'), isNull);
  });

  test('shouldLeaveLoginWhenSignedIn', () {
    expect(redirect(signedIn, '/login'), '/');
    expect(redirect(signedIn, '/login?reason=expired'), '/');
    expect(redirect(signedIn, '/'), isNull);
  });

  test('shouldReturnToInAppFromPathOnlyWhenSignedIn', () {
    expect(redirect(signedIn, '/login?from=%2Fplan%3Ftab%3D1'), '/plan?tab=1');
    expect(redirect(signedIn, '/login?from=%2F%2Fevil.example'), '/');
    expect(redirect(signedIn, '/login?from=https%3A%2F%2Fevil.example'), '/');
    expect(redirect(signedIn, '/login?from=%2Flogin'), '/');
  });
}
