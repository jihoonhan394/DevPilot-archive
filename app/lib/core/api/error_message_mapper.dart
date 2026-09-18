import 'package:devpilot_app/core/api/api_exception.dart';
import 'package:devpilot_app/l10n/app_localizations.dart';

/// User-facing message for [error] (docs/08 §8.5): mapped code → ARB, else server `detail`,
/// else [AppLocalizations.errorGeneric].
String messageFor(Object error, AppLocalizations l10n) {
  if (error is! ApiException) {
    return l10n.errorGeneric;
  }
  switch (error.code) {
    case ApiErrorCode.userNotAllowed:
      return l10n.loginNotAllowed;
    case ApiErrorCode.rateLimited:
      return l10n.errorRateLimited;
    case ApiErrorCode.networkError || ApiErrorCode.clientTimeout:
      return l10n.errorNetworkError;
    case ApiErrorCode.internalError:
      return l10n.errorInternalError;
  }
  final detail = error.detail;
  return detail == null || detail.isEmpty ? l10n.errorGeneric : detail;
}
