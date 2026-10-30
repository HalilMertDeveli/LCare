import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/state_views.dart';
import '../../l10n/generated/app_localizations.dart';

/// Shown while the stored session is being restored (`GET /api/me`).
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const Key('splashScreen'),
      backgroundColor: BrandColors.navy,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(onDark: true, size: 34),
                const SizedBox(height: 32),
                if (auth is AuthRestoreFailed) ...[
                  Text(
                    errorMessage(l10n, auth.error),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    key: const Key('retryButton'),
                    onPressed: () => ref.read(authControllerProvider.notifier).restore(),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.retry),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                    style: TextButton.styleFrom(foregroundColor: Colors.white70),
                    child: Text(l10n.logout),
                  ),
                ] else
                  const SizedBox.square(
                    dimension: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
