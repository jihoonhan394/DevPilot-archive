import 'package:freezed_annotation/freezed_annotation.dart';

part 'me_response.freezed.dart';
part 'me_response.g.dart';

/// S0 walking-skeleton body of `GET /api/v1/me`: the JWT subject and email.
///
/// Replaced by the full `MeResponse` of docs/05 §3.1 in S1 (BL-FND-21).
@freezed
abstract class MeResponse with _$MeResponse {
  const factory MeResponse({required String sub, String? email}) = _MeResponse;

  factory MeResponse.fromJson(Map<String, Object?> json) => _$MeResponseFromJson(json);
}
