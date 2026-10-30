import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/app_localizations.dart';

enum ShellKind { customer, admin, technician }

/// Bottom-navigation shell shared by the three role areas.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.shell, required this.kind});

  final StatefulNavigationShell shell;
  final ShellKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (IconData icon, IconData selected, String label) first = switch (kind) {
      ShellKind.customer => (Icons.receipt_long_outlined, Icons.receipt_long, l10n.navMyRequests),
      ShellKind.admin => (Icons.dashboard_outlined, Icons.dashboard, l10n.navRequests),
      ShellKind.technician => (Icons.handyman_outlined, Icons.handyman, l10n.navJobs),
    };
    return Scaffold(
      key: Key('shell-${kind.name}'),
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(
            key: const Key('nav-0'),
            icon: Icon(first.$1),
            selectedIcon: Icon(first.$2),
            label: first.$3,
          ),
          NavigationDestination(
            key: const Key('nav-1'),
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
