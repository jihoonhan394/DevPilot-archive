import 'package:devpilot_app/core/auth/auth_controller.dart';
import 'package:devpilot_app/core/theme/app_theme.dart';
import 'package:devpilot_app/core/widgets/error_view.dart';
import 'package:devpilot_app/features/home/data/me_response.dart';
import 'package:devpilot_app/features/home/presentation/me_provider.dart';
import 'package:devpilot_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// S0 walking skeleton: shows the `GET /api/v1/me` result after login. Replaced by SCR-TODAY/PLAN.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(meProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          TextButton(
            key: const Key('home.logoutButton'),
            onPressed: () => ref.read(authStateProvider.notifier).signOut(),
            child: Text(l10n.homeLogoutButton),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: me.when(
                skipLoadingOnRefresh: false,
                data: (profile) => _ProfileCard(profile: profile),
                error: (error, _) =>
                    ErrorView(error: error, onRetry: () => ref.invalidate(meProvider)),
                loading: () => const _ProfileSkeleton(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final MeResponse profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    // SelectionArea + Text, not SelectableText: on the web SelectableText reaches screen readers as
    // an empty read-only field (docs/02 A-6).
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.homeProfileTitle, style: textTheme.titleMedium),
              const SizedBox(height: 16),
              Text(l10n.homeEmailLabel, style: textTheme.bodySmall),
              Text(profile.email ?? '—', key: const Key('home.email'), style: textTheme.bodyLarge),
              const SizedBox(height: 12),
              Text(l10n.homeUserIdLabel, style: textTheme.bodySmall),
              Text(profile.sub, style: AppTheme.codeTextStyle),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonBlock(width: 120),
            _SkeletonBlock(width: 240),
            _SkeletonBlock(width: 200),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 16,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
    );
  }
}
