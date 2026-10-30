/// DTOs mirroring `packages/contracts/openapi.json` (ServiceRequests tag).
library;

enum ServiceRequestStatus {
  newRequest('New'),
  inReview('InReview'),
  inProgress('InProgress'),
  waitingForCustomer('WaitingForCustomer'),
  resolved('Resolved'),
  closed('Closed'),
  cancelled('Cancelled');

  const ServiceRequestStatus(this.apiValue);

  /// Wire value (enums are serialized as strings).
  final String apiValue;

  static ServiceRequestStatus fromJson(String value) => values.firstWhere(
        (s) => s.apiValue == value,
        orElse: () => throw FormatException('Unknown ServiceRequestStatus: $value'),
      );

  String toJson() => apiValue;

  bool get isTerminal => this == closed || this == cancelled;
}

DateTime _date(Object? v) => DateTime.parse(v as String).toLocal();

/// `version` is `uint32` on the wire.
int _uint(Object? v) => (v as num).toInt();

class ServiceRequestSummary {
  const ServiceRequestSummary({
    required this.id,
    required this.referenceCode,
    required this.title,
    required this.status,
    required this.customerId,
    required this.customerName,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory ServiceRequestSummary.fromJson(Map<String, dynamic> json) =>
      ServiceRequestSummary(
        id: json['id'] as String,
        referenceCode: json['referenceCode'] as String,
        title: json['title'] as String,
        status: ServiceRequestStatus.fromJson(json['status'] as String),
        customerId: json['customerId'] as String,
        customerName: json['customerName'] as String,
        createdAt: _date(json['createdAt']),
        updatedAt: _date(json['updatedAt']),
        version: _uint(json['version']),
      );

  final String id;
  final String referenceCode;
  final String title;
  final ServiceRequestStatus status;
  final String customerId;
  final String customerName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
}

class StatusHistoryEntry {
  const StatusHistoryEntry({
    required this.fromStatus,
    required this.toStatus,
    required this.changedAt,
    required this.changedBy,
    required this.note,
  });

  factory StatusHistoryEntry.fromJson(Map<String, dynamic> json) =>
      StatusHistoryEntry(
        fromStatus: json['fromStatus'] == null
            ? null
            : ServiceRequestStatus.fromJson(json['fromStatus'] as String),
        toStatus: ServiceRequestStatus.fromJson(json['toStatus'] as String),
        changedAt: _date(json['changedAt']),
        changedBy: json['changedBy'] as String,
        note: json['note'] as String?,
      );

  final ServiceRequestStatus? fromStatus;
  final ServiceRequestStatus toStatus;
  final DateTime changedAt;
  final String changedBy;
  final String? note;
}

class ServiceRequestDetail extends ServiceRequestSummary {
  const ServiceRequestDetail({
    required super.id,
    required super.referenceCode,
    required super.title,
    required super.status,
    required super.customerId,
    required super.customerName,
    required super.createdAt,
    required super.updatedAt,
    required super.version,
    required this.description,
    required this.allowedTransitions,
    required this.history,
  });

  factory ServiceRequestDetail.fromJson(Map<String, dynamic> json) {
    final s = ServiceRequestSummary.fromJson(json);
    return ServiceRequestDetail(
      id: s.id,
      referenceCode: s.referenceCode,
      title: s.title,
      status: s.status,
      customerId: s.customerId,
      customerName: s.customerName,
      createdAt: s.createdAt,
      updatedAt: s.updatedAt,
      version: s.version,
      description: json['description'] as String,
      allowedTransitions: (json['allowedTransitions'] as List<dynamic>)
          .map((e) => ServiceRequestStatus.fromJson(e as String))
          .toList(),
      history: (json['history'] as List<dynamic>)
          .map((e) => StatusHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String description;

  /// Computed by the server for the caller â€” the only actions to render.
  final List<ServiceRequestStatus> allowedTransitions;
  final List<StatusHistoryEntry> history;
}

class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) item,
  ) =>
      PagedResult(
        items: (json['items'] as List<dynamic>)
            .map((e) => item(e as Map<String, dynamic>))
            .toList(),
        page: (json['page'] as num).toInt(),
        pageSize: (json['pageSize'] as num).toInt(),
        totalCount: (json['totalCount'] as num).toInt(),
      );

  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;
}
