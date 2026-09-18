import 'package:devpilot_app/core/api/api_exception.dart';
import 'package:devpilot_app/core/api/error_message_mapper.dart';
import 'package:devpilot_app/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('ko'));

  test('shouldUseArbMessageWhenCodeIsMapped', () {
    const error = ApiException(code: ApiErrorCode.userNotAllowed, status: 403, detail: '서버 문구');

    expect(messageFor(error, l10n), '허용된 사용자가 아닙니다.');
  });

  test('shouldUseServerDetailWhenCodeIsNotMapped', () {
    const error = ApiException(code: 'PLAN_NOT_FOUND', status: 404, detail: '학습 계획을 찾을 수 없습니다.');

    expect(messageFor(error, l10n), '학습 계획을 찾을 수 없습니다.');
  });

  test('shouldUseGenericMessageWhenNeitherCodeNorDetailIsKnown', () {
    expect(messageFor(const ApiException(code: 'SOMETHING_NEW'), l10n), l10n.errorGeneric);
    expect(messageFor(StateError('not an api error'), l10n), l10n.errorGeneric);
  });
}
