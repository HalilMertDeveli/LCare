import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/realtime/realtime_indicator.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/status_style.dart';
import '../../../core/widgets/formatting.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/service_request_models.dart';
import '../data/service_request_providers.dart';

enum RequestListMode { customer, staff }

class RequestListScreen extends ConsumerStatefulWidget {
  const RequestListScreen({super.key, required this.mode, required this.basePath});

  final RequestListMode mode;

  /// Detail pages are pushed at `$basePath/<id>`.
  final String basePath;

  @override
  ConsumerState<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends ConsumerState<RequestListScreen> {
  ServiceRequestStatus? _filter;

  bool get _staff => widget.mode == RequestListMode.staff;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = serviceRequestListProvider(_filter);
    final requests = ref.watch(provider);

    Future<void> refresh() => ref.refresh(provider.future).then((_) {}, onError: (_) {});

    return Scaffold(
      key: Key('requestList-${widget.mode.name}'),
      appBar: AppBar(
        title: Text(_staff ? l10n.allRequestsTitle : l10n.myRequestsTitle),
        actions: const [RealtimeIndicator(), SizedBox(width: 4)],
        bottom: _staff
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: _StatusFilterBar(
                  selected: _filter,
                  onSelected: (s) => setState(() => _filter = s),
                ),
              )
            : null,
      ),
      floatingActionButton: _staff
          ? null
          : FloatingActionButton.extended(
              key: const Key('newRequestButton'),
              onPressed: () => context.push(Routes.customerNewRequest),
              icon: const Icon(Icons.add),
              label: Text(l10n.newRequest),
            ),
      body: requests.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(provider)),
        data: (page) {
          if (page.items.isEmpty) {
            return RefreshIndicator(
              onRefresh: refresh,
              child: MessageView(
                key: const Key('emptyRequests'),
                icon: Icons.inbox_outlined,
                title: _filter != null
                    ? l10n.emptyRequestsFiltered
                    : (_staff ? l10n.emptyRequests : l10n.emptyRequestsCustomer),
              ),
            );
          }
          final truncated = page.totalCount > page.items.length;
          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView.separated(
              key: const Key('requestListView'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: page.items.length + (truncated ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == page.items.length) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      l10n.listTruncated(page.items.length, page.totalCount),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }
                final item = page.items[i];
                return RequestCard(
                  item: item,
                  showCustomer: _staff,
                  onTap: () => context.push('${widget.basePath}/${item.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({required this.selected, required this.onSelected});

  final ServiceRequestStatus? selected;
  final ValueChanged<ServiceRequestStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = <ServiceRequestStatus?>[null, ...ServiceRequestStatus.values];
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final s = options[i];
          return ChoiceChip(
            key: Key('filter-${s?.apiValue ?? 'all'}'),
            label: Text(s == null ? l10n.filterAll : statusLabel(l10n, s)),
            avatar: s == null
                ? null
                : CircleAvatar(backgroundColor: statusBaseColor(s), radius: 5),
            showCheckmark: false,
            selected: selected == s,
            onSelected: (_) => onSelected(s),
          );
        },
      ),
    );
  }
}

class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.item,
    required this.showCustomer,
    required this.onTap,
  });

  final ServiceRequestSummary item;
  final bool showCustomer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Card(
      key: Key('request-${item.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    item.referenceCode,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Spacer(),
                  StatusChip(item.status, dense: true),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (showCustomer) ...[
                    Icon(Icons.business_outlined, size: 14, color: muted?.color),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(item.customerName,
                          style: muted, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Icon(Icons.schedule, size: 14, color: muted?.color),
                  const SizedBox(width: 4),
                  Text(formatDateTime(context, item.updatedAt), style: muted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
