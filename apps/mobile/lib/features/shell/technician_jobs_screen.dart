import 'package:material_ui/material_ui.dart';

import '../../core/realtime/realtime_indicator.dart';
import '../../core/widgets/state_views.dart';
import '../../l10n/generated/app_localizations.dart';

/// Phase 0: assignments do not exist yet, so technicians see an honest empty
/// state instead of a request list.
class TechnicianJobsScreen extends StatelessWidget {
  const TechnicianJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.jobsTitle),
        actions: const [RealtimeIndicator()],
      ),
      body: MessageView(
        key: const Key('technicianEmpty'),
        icon: Icons.assignment_outlined,
        title: l10n.emptyTechnicianJobs,
        message: l10n.emptyTechnicianJobsDetail,
      ),
    );
  }
}
