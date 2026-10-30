import 'package:material_ui/material_ui.dart';

import '../../features/service_requests/data/service_request_models.dart';
import '../../l10n/generated/app_localizations.dart';

/// Status colour coding shared with the web client.
Color statusBaseColor(ServiceRequestStatus status) => switch (status) {
      ServiceRequestStatus.newRequest => const Color(0xFF2F6BFF), // blue
      ServiceRequestStatus.inReview => const Color(0xFF5B5BD6), // indigo
      ServiceRequestStatus.inProgress => const Color(0xFFD99A00), // amber
      ServiceRequestStatus.waitingForCustomer => const Color(0xFFEA6A12), // orange
      ServiceRequestStatus.resolved => const Color(0xFF1F9D55), // green
      ServiceRequestStatus.closed => const Color(0xFF6B7587), // gray
      ServiceRequestStatus.cancelled => const Color(0xFFD64545), // red
    };

IconData statusIcon(ServiceRequestStatus status) => switch (status) {
      ServiceRequestStatus.newRequest => Icons.add_circle_outline,
      ServiceRequestStatus.inReview => Icons.manage_search,
      ServiceRequestStatus.inProgress => Icons.build_outlined,
      ServiceRequestStatus.waitingForCustomer => Icons.hourglass_bottom,
      ServiceRequestStatus.resolved => Icons.check_circle_outline,
      ServiceRequestStatus.closed => Icons.lock_outline,
      ServiceRequestStatus.cancelled => Icons.cancel_outlined,
    };

/// Turkish labels from contracts.md (via ARB).
String statusLabel(AppLocalizations l10n, ServiceRequestStatus status) =>
    switch (status) {
      ServiceRequestStatus.newRequest => l10n.statusNew,
      ServiceRequestStatus.inReview => l10n.statusInReview,
      ServiceRequestStatus.inProgress => l10n.statusInProgress,
      ServiceRequestStatus.waitingForCustomer => l10n.statusWaitingForCustomer,
      ServiceRequestStatus.resolved => l10n.statusResolved,
      ServiceRequestStatus.closed => l10n.statusClosed,
      ServiceRequestStatus.cancelled => l10n.statusCancelled,
    };

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key, this.dense = false});

  final ServiceRequestStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final base = statusBaseColor(status);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Color.lerp(base, Colors.white, 0.35)! : Color.lerp(base, Colors.black, 0.15)!;
    final label = statusLabel(AppLocalizations.of(context), status);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
        decoration: BoxDecoration(
          color: base.withValues(alpha: dark ? 0.22 : 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: base.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon(status), size: dense ? 13 : 15, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: dense ? 12 : 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
