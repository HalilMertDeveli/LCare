import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/app_localizations.dart';
import 'realtime_connection.dart';
import 'realtime_controller.dart';

/// Small dot in the app bar: green = live, amber = connecting, gray = off.
class RealtimeIndicator extends ConsumerWidget {
  const RealtimeIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(realtimeControllerProvider);
    final l10n = AppLocalizations.of(context);
    final (color, label) = switch (status) {
      RealtimeStatus.connected => (const Color(0xFF1F9D55), l10n.realtimeConnected),
      RealtimeStatus.connecting => (const Color(0xFFD99A00), l10n.realtimeConnecting),
      RealtimeStatus.disconnected => (const Color(0xFF8A93A3), l10n.realtimeDisconnected),
    };
    return Tooltip(
      message: label,
      triggerMode: TooltipTriggerMode.tap,
      child: Semantics(
        label: label,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: AnimatedContainer(
              key: ValueKey('realtime-${status.name}'),
              duration: const Duration(milliseconds: 250),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  if (status == RealtimeStatus.connected)
                    BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
