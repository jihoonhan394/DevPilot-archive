import 'package:devpilot_app/app/router.dart';
import 'package:devpilot_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// SCR-NOT-FOUND: unknown routes (docs/02 §3.15).
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 48, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 16),
                Text(l10n.notFoundTitle, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(l10n.notFoundBody, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: Text(l10n.notFoundHome),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
