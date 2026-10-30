import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/realtime/realtime_indicator.dart';
import '../../../core/realtime/refresh_signal.dart';
import '../../../core/theme/status_style.dart';
import '../../../core/widgets/formatting.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/service_request_models.dart';
import '../data/service_request_providers.dart';
import 'create_request_screen.dart' show RequestValidation;

class RequestDetailScreen extends ConsumerStatefulWidget {
  const RequestDetailScreen({super.key, required this.id, required this.staffView});

  final String id;

  /// Staff see every allowed transition; customers only "Talebi iptal et".
  final bool staffView;

  @override
  ConsumerState<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends ConsumerState<RequestDetailScreen> {
  bool _busy = false;

  Future<void> _changeStatus(ServiceRequestDetail detail, ServiceRequestStatus target) async {
    final l10n = AppLocalizations.of(context);
    final result = await showModalBottomSheet<_TransitionResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _TransitionSheet(target: target, customerCancel: !widget.staffView),
    );
    if (result == null || !mounted) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(serviceRequestRepositoryProvider).changeStatus(
            id: detail.id,
            status: target,
            version: detail.version,
            note: result.note,
          );
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.statusChanged(statusLabel(l10n, target)))),
      );
    } on ApiException catch (e) {
      if (e.kind == ApiErrorKind.conflict) {
        messenger.showSnackBar(SnackBar(
          key: const Key('staleSnack'),
          content: Text('${l10n.errorStale}. ${l10n.errorStaleDetail}'),
        ));
      } else {
        messenger.showSnackBar(SnackBar(content: Text(errorMessage(l10n, e))));
      }
    } finally {
      // Success, conflict or failure: reload from REST so the screen shows
      // the server's truth (version, allowedTransitions, history). The bump
      // invalidates this detail provider and every live list.
      if (mounted) {
        ref.read(refreshSignalProvider.notifier).bump();
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = serviceRequestDetailProvider(widget.id);
    final detail = ref.watch(provider);

    return Scaffold(
      key: const Key('requestDetailScreen'),
      appBar: AppBar(
        title: Text(detail.value?.referenceCode ?? l10n.detailTitle),
        actions: const [RealtimeIndicator(), SizedBox(width: 4)],
      ),
      body: detail.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(provider)),
        data: (d) => RefreshIndicator(
          onRefresh: () => ref.refresh(provider.future).then((_) {}, onError: (_) {}),
          child: Stack(
            children: [
              ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _Header(detail: d, showCustomer: widget.staffView),
                  const SizedBox(height: 12),
                  _Section(
                    title: l10n.descriptionSection,
                    child: SelectableText(d.description, key: const Key('detailDescription')),
                  ),
                  const SizedBox(height: 12),
                  _Actions(
                    detail: d,
                    staffView: widget.staffView,
                    busy: _busy,
                    onSelected: (s) => _changeStatus(d, s),
                  ),
                  _Section(
                    title: l10n.historySection,
                    child: _History(entries: d.history),
                  ),
                ],
              ),
              if (_busy) const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.detail, required this.showCustomer});

  final ServiceRequestDetail detail;
  final bool showCustomer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusChip(detail.status, key: const Key('detailStatus')),
            const SizedBox(height: 12),
            Text(
              detail.title,
              key: const Key('detailTitle'),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (showCustomer) _Meta(label: l10n.customerLabel, value: detail.customerName, style: muted),
            _Meta(label: l10n.createdLabel, value: formatDateTime(context, detail.createdAt), style: muted),
            _Meta(label: l10n.updatedLabel, value: formatDateTime(context, detail.updatedAt), style: muted),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value, this.style});

  final String label;
  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 120, child: Text(label, style: style)),
            Expanded(
              child: Text(value, style: style?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
            ),
          ],
        ),
      );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.detail,
    required this.staffView,
    required this.busy,
    required this.onSelected,
  });

  final ServiceRequestDetail detail;
  final bool staffView;
  final bool busy;
  final ValueChanged<ServiceRequestStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allowed = detail.allowedTransitions;

    if (!staffView) {
      // Customers: only cancellation, and only if the server allows it.
      if (!allowed.contains(ServiceRequestStatus.cancelled)) return const SizedBox.shrink();
      final error = Theme.of(context).colorScheme.error;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: OutlinedButton.icon(
          key: const Key('cancelRequestButton'),
          onPressed: busy ? null : () => onSelected(ServiceRequestStatus.cancelled),
          icon: const Icon(Icons.cancel_outlined),
          label: Text(l10n.cancelRequest),
          style: OutlinedButton.styleFrom(
            foregroundColor: error,
            side: BorderSide(color: error.withValues(alpha: 0.5)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Section(
        title: l10n.actionsSection,
        child: allowed.isEmpty
            ? Text(l10n.noActions, key: const Key('noActions'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final s in allowed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: FilledButton.tonalIcon(
                        key: Key('transition-${s.apiValue}'),
                        onPressed: busy ? null : () => onSelected(s),
                        icon: Icon(statusIcon(s)),
                        label: Text(l10n.changeStatusTo(statusLabel(l10n, s))),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          alignment: Alignment.centerLeft,
                          foregroundColor: Color.lerp(
                            statusBaseColor(s),
                            Theme.of(context).colorScheme.onSurface,
                            0.25,
                          ),
                          backgroundColor: statusBaseColor(s).withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.entries});

  final List<StatusHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ordered = [...entries]..sort((a, b) => b.changedAt.compareTo(a.changedAt));
    return Column(
      key: const Key('historyList'),
      children: [
        for (var i = 0; i < ordered.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      CircleAvatar(radius: 6, backgroundColor: statusBaseColor(ordered[i].toStatus)),
                      if (i != ordered.length - 1)
                        Expanded(child: VerticalDivider(width: 2, color: theme.colorScheme.outline)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (ordered[i].fromStatus == null)
                              Text(l10n.historyCreated,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600))
                            else ...[
                              StatusChip(ordered[i].fromStatus!, dense: true),
                              Icon(Icons.arrow_forward, size: 14, color: theme.colorScheme.onSurfaceVariant),
                            ],
                            StatusChip(ordered[i].toStatus, dense: true),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${ordered[i].changedBy} · ${formatDateTime(context, ordered[i].changedAt)}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        if (ordered[i].note != null && ordered[i].note!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(ordered[i].note!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TransitionResult {
  const _TransitionResult(this.note);
  final String? note;
}

class _TransitionSheet extends StatefulWidget {
  const _TransitionSheet({required this.target, required this.customerCancel});

  final ServiceRequestStatus target;
  final bool customerCancel;

  @override
  State<_TransitionSheet> createState() => _TransitionSheetState();
}

class _TransitionSheetState extends State<_TransitionSheet> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final label = statusLabel(l10n, widget.target);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Column(
          key: const Key('transitionSheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.customerCancel ? l10n.cancelRequest : l10n.changeStatusTo(label),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (widget.customerCancel) ...[
              const SizedBox(height: 6),
              Text(l10n.cancelRequestConfirm),
            ],
            const SizedBox(height: 16),
            TextField(
              key: const Key('transitionNote'),
              controller: _note,
              minLines: 2,
              maxLines: 5,
              maxLength: RequestValidation.noteMax,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.noteLabel),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('confirmTransition'),
              style: widget.target == ServiceRequestStatus.cancelled
                  ? FilledButton.styleFrom(backgroundColor: theme.colorScheme.error)
                  : null,
              onPressed: () => Navigator.of(context).pop(_TransitionResult(_note.text)),
              child: Text(l10n.confirm),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }
}
