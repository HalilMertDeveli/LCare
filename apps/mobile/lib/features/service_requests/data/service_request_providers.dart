import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/realtime/refresh_signal.dart';
import 'service_request_models.dart';
import 'service_request_repository.dart';

final serviceRequestRepositoryProvider = Provider<ServiceRequestRepository>(
  (ref) => ApiServiceRequestRepository(ref.watch(apiClientProvider).dio),
);

/// Page size used by the Phase 0 lists (no infinite scroll yet).
const kRequestListPageSize = 50;

/// Requests visible to the caller, optionally filtered by status
/// (`null` = all). The server scopes the list by role.
final serviceRequestListProvider = FutureProvider.autoDispose
    .family<PagedResult<ServiceRequestSummary>, ServiceRequestStatus?>(
  (ref, status) {
    ref.watch(refreshSignalProvider);
    return ref
        .watch(serviceRequestRepositoryProvider)
        .list(status: status, pageSize: kRequestListPageSize);
  },
);

final serviceRequestDetailProvider =
    FutureProvider.autoDispose.family<ServiceRequestDetail, String>(
  (ref, id) {
    ref.watch(refreshSignalProvider);
    return ref.watch(serviceRequestRepositoryProvider).get(id);
  },
);
