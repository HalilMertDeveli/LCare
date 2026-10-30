import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/widgets/state_views.dart';
import '../../l10n/generated/app_localizations.dart';

class NoAccessScreen extends ConsumerWidget {
  const NoAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: MessageView(
          icon: Icons.block_outlined,
          title: l10n.noAccessTitle,
          message: l10n.noAccessDetail,
          action: OutlinedButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            label: Text(l10n.logout),
          ),
        ),
      ),
    );
  }
}
