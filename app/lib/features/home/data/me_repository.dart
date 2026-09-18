import 'package:devpilot_app/core/api/api_client.dart';
import 'package:devpilot_app/features/home/data/me_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class MeRepository {
  /// `GET /api/v1/me`. Throws `ApiException`.
  Future<MeResponse> fetchMe();
}

final class ApiMeRepository implements MeRepository {
  ApiMeRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<MeResponse> fetchMe() async => MeResponse.fromJson(await _apiClient.getJson('/me'));
}

final meRepositoryProvider = Provider<MeRepository>(
  (ref) => ApiMeRepository(ref.watch(apiClientProvider)),
);
