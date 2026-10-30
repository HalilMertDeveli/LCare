import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/auth_models.dart';
import '../../core/realtime/realtime_indicator.dart';
import '../../l10n/generated/app_localizations.dart';

String roleLabel(AppLocalizations l10n, OrganizationRole role) => switch (role) {
      OrganizationRole.serviceManager => l10n.roleServiceManager,
      OrganizationRole.dispatcher => l10n.roleDispatcher,
      OrganizationRole.remoteSupportTechnician => l10n.roleRemoteSupportTechnician,
      OrganizationRole.fieldTechnician => l10n.roleFieldTechnician,
      OrganizationRole.customer => l10n.roleCustomer,
    };

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    if (auth is! AuthSignedIn) return const SizedBox.shrink();
    final me = auth.me;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: const [RealtimeIndicator()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    child: Text(
                      me.displayName.isEmpty ? '?' : me.displayName.characters.first.toUpperCase(),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(me.displayName,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(me.email,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final m in me.memberships)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.organizationLabel,
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 2),
                      Text(m.organizationName, style: theme.textTheme.titleSmall),
                      if (m.customerName != null) ...[
                        const SizedBox(height: 10),
                        Text(l10n.customerLabel,
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        Text(m.customerName!, style: theme.textTheme.titleSmall),
                      ],
                      const SizedBox(height: 10),
                      Text(l10n.rolesLabel,
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (me.platformRoles.contains(kPlatformSuperAdmin))
                            Chip(label: Text(l10n.rolePlatformSuperAdmin)),
                          for (final r in m.roles) Chip(label: Text(roleLabel(l10n, r))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('logoutButton'),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            label: Text(l10n.logout),
            style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
          ),
        ],
      ),
    );
  }
}
