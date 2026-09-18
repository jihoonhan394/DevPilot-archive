import 'package:devpilot_app/core/api/api_exception.dart';
import 'package:devpilot_app/core/api/error_message_mapper.dart';
import 'package:devpilot_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Full-area error for failed loads (docs/02 §3.3): message, retry, and a collapsed report
/// section with the error code and traceId.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final failure = error;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.error_outline, size: 48, color: colorScheme.error),
        const SizedBox(height: 12),
        Text(
          messageFor(failure, l10n),
          key: const Key('common.errorMessage'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: onRetry, child: Text(l10n.commonErrorRetry)),
        if (failure is ApiException) _ReportInfo(failure: failure),
      ],
    );
  }
}

class _ReportInfo extends StatelessWidget {
  const _ReportInfo({required this.failure});

  final ApiException failure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final traceId = failure.traceId;
    // SelectionArea + Text, not SelectableText: on the web SelectableText reaches screen readers as
    // an empty read-only field (docs/02 A-6).
    return ExpansionTile(
      title: Text(l10n.commonErrorReportInfo),
      children: [
        SelectionArea(
          child: Column(
            children: [
              ListTile(
                dense: true,
                title: Text(l10n.commonErrorCodeLabel),
                subtitle: Text(failure.code),
              ),
              if (traceId != null)
                ListTile(
                  dense: true,
                  title: Text(l10n.commonErrorTraceIdLabel),
                  subtitle: Text(traceId),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
