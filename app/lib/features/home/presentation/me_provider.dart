import 'package:devpilot_app/core/auth/auth_controller.dart';
import 'package:devpilot_app/features/home/data/me_repository.dart';
import 'package:devpilot_app/features/home/data/me_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `GET /me` for the signed-in user. Re-fetched when the access token changes.
final meProvider = FutureProvider.autoDispose<MeResponse>((ref) {
  ref.watch(authStateProvider.select((authState) => authState.accessToken));
  return ref.watch(meRepositoryProvider).fetchMe();
});
