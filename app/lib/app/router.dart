import 'package:devpilot_app/app/not_found_screen.dart';
import 'package:devpilot_app/core/auth/auth_controller.dart';
import 'package:devpilot_app/features/auth/presentation/login_screen.dart';
import 'package:devpilot_app/features/home/presentation/home_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  /// S0 home (`GET /me` result). Becomes a redirect to `/plan` (S1) and `/today` (S2).
  static const home = '/';
  static const login = '/login';

  static const _authenticated = {home};

  static bool requiresAuth(String path) => _authenticated.contains(path);
}

/// Redirect rules 1–2 of docs/02 §2.4. Returns null to stay on [location].
String? redirectForAuth(AuthState authState, Uri location) {
  final isLoginRoute = location.path == AppRoutes.login;
  switch (authState) {
    case SignedIn():
      return isLoginRoute ? _returnPath(location.queryParameters['from']) : null;
    case SignedOut(:final reason):
      if (isLoginRoute || !AppRoutes.requiresAuth(location.path)) {
        return null;
      }
      final queryParameters = {
        if (location.path != AppRoutes.home) 'from': location.toString(),
        'reason': ?reason?.name,
      };
      return Uri(
        path: AppRoutes.login,
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      ).toString();
  }
}

/// Accepts only in-app paths so `from` cannot point to another origin.
String _returnPath(String? from) {
  if (from == null || !from.startsWith('/') || from.startsWith('//')) {
    return AppRoutes.home;
  }
  return Uri.parse(from).path == AppRoutes.login ? AppRoutes.home : from;
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ValueNotifier<AuthState>(const SignedOut());
  ref.listen<AuthState>(
    authStateProvider,
    (_, next) => authState.value = next,
    fireImmediately: true,
  );
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: authState,
    redirect: (context, state) => redirectForAuth(authState.value, state.uri),
    routes: [
      GoRoute(path: AppRoutes.home, builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => LoginScreen(reason: state.uri.queryParameters['reason']),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
  ref.onDispose(() {
    router.dispose();
    authState.dispose();
  });
  return router;
});
