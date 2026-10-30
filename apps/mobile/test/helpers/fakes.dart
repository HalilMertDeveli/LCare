import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ledcare_mobile/core/network/api_exception.dart';
import 'package:ledcare_mobile/core/realtime/realtime_connection.dart';
import 'package:ledcare_mobile/features/service_requests/data/service_request_models.dart';
import 'package:ledcare_mobile/features/service_requests/data/service_request_repository.dart';

class FakeResponse {
  const FakeResponse(this.status, [this.body]);
  final int status;
  final Object? body;
}

typedef FakeHandler = FutureOr<FakeResponse> Function(RequestOptions request);

/// Dio adapter that answers from [handler] and records every request.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  FakeHandler handler;
  final requests = <RequestOptions>[];

  List<RequestOptions> to(String path) =>
      requests.where((r) => r.path == path).toList();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final r = await handler(options);
    if (r.status == -1) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'fake network down',
      );
    }
    final isProblem = r.status >= 400;
    return ResponseBody.fromString(
      r.body == null ? '' : jsonEncode(r.body),
      r.status,
      headers: {
        Headers.contentTypeHeader: [
          isProblem ? 'application/problem+json' : 'application/json',
        ],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const network = FakeResponse(-1);

// ---------------------------------------------------------------- fixtures

const orgId = '0193a000-0000-7000-8000-000000000001';
const customerAId = '0193a000-0000-7000-8000-0000000000a1';

Map<String, dynamic> meJson({
  List<String> platformRoles = const [],
  List<String> roles = const ['Customer'],
  String email = 'musteri.a@ledcare.local',
  String name = 'Ayşe Müşteri',
}) =>
    {
      'userId': '01a18ba5-fba7-73cf-a8b2-6320386856de',
      'email': email,
      'displayName': name,
      'platformRoles': platformRoles,
      'memberships': [
        {
          'organizationId': orgId,
          'organizationName': 'LEDCare Merkez Teknik Servis',
          'roles': roles,
          'customerId': roles.contains('Customer') ? customerAId : null,
          'customerName': roles.contains('Customer') ? 'Örnek Reklam A.Ş.' : null,
        }
      ],
    };

final customerMe = meJson();
final staffMe = meJson(
  platformRoles: ['PlatformSuperAdmin'],
  roles: ['ServiceManager'],
  email: 'admin@ledcare.local',
  name: 'Admin',
);
final technicianMe = meJson(
  roles: ['FieldTechnician'],
  email: 'saha.teknisyen@ledcare.local',
  name: 'Saha Teknisyeni',
);

Map<String, dynamic> tokenJson(String access, String refresh) => {
      'tokenType': 'Bearer',
      'accessToken': access,
      'expiresIn': 900,
      'refreshToken': refresh,
    };

Map<String, dynamic> summaryJson({
  String id = '01a18ba6-ca33-7417-8680-a2dd8ed9791b',
  String ref = 'LC-000001',
  String title = 'Ekranda ölü pikseller',
  String status = 'New',
  int version = 7,
}) =>
    {
      'id': id,
      'referenceCode': ref,
      'title': title,
      'status': status,
      'customerId': customerAId,
      'customerName': 'Örnek Reklam A.Ş.',
      'createdAt': '2026-10-30T07:12:06.195244+00:00',
      'updatedAt': '2026-10-30T07:12:06.398325+00:00',
      'version': version,
    };

Map<String, dynamic> detailJson({
  String id = '01a18ba6-ca33-7417-8680-a2dd8ed9791b',
  String title = 'Ekranda ölü pikseller',
  String status = 'New',
  int version = 7,
  List<String> allowed = const ['InReview', 'InProgress', 'Cancelled'],
}) =>
    {
      ...summaryJson(id: id, title: title, status: status, version: version),
      'description': 'Sol alt modülde ölü pikseller var.',
      'allowedTransitions': allowed,
      'history': [
        {
          'fromStatus': null,
          'toStatus': 'New',
          'changedAt': '2026-10-30T07:12:06.195244+00:00',
          'changedBy': 'Ayşe Müşteri',
          'note': null,
        },
        if (status != 'New')
          {
            'fromStatus': 'New',
            'toStatus': status,
            'changedAt': '2026-10-30T08:00:00+00:00',
            'changedBy': 'Admin',
            'note': 'İnceleniyor',
          },
      ],
    };

// ---------------------------------------------------------- repository

class FakeServiceRequestRepository implements ServiceRequestRepository {
  FakeServiceRequestRepository({
    List<ServiceRequestSummary>? items,
    Map<String, ServiceRequestDetail>? details,
  })  : items = items ?? [ServiceRequestSummary.fromJson(summaryJson())],
        details = details ??
            {
              '01a18ba6-ca33-7417-8680-a2dd8ed9791b':
                  ServiceRequestDetail.fromJson(detailJson()),
            };

  List<ServiceRequestSummary> items;
  Map<String, ServiceRequestDetail> details;
  int listCalls = 0;
  int getCalls = 0;
  final listStatuses = <ServiceRequestStatus?>[];
  Object? createError;
  Object? changeError;
  final changes = <({String id, ServiceRequestStatus status, int version, String? note})>[];
  final created = <({String title, String description})>[];

  @override
  Future<PagedResult<ServiceRequestSummary>> list({
    ServiceRequestStatus? status,
    int page = 1,
    int pageSize = 50,
  }) async {
    listCalls++;
    listStatuses.add(status);
    final filtered = status == null ? items : items.where((i) => i.status == status).toList();
    return PagedResult(items: filtered, page: page, pageSize: pageSize, totalCount: filtered.length);
  }

  @override
  Future<ServiceRequestDetail> get(String id) async {
    getCalls++;
    final d = details[id];
    if (d == null) throw const ApiException(kind: ApiErrorKind.notFound, statusCode: 404);
    return d;
  }

  @override
  Future<ServiceRequestDetail> create({required String title, required String description}) async {
    if (createError != null) throw createError!;
    created.add((title: title, description: description));
    final d = ServiceRequestDetail.fromJson(
      detailJson(id: 'new-id', title: title, allowed: const ['Cancelled']),
    );
    details[d.id] = d;
    items = [d, ...items];
    return d;
  }

  @override
  Future<ServiceRequestDetail> changeStatus({
    required String id,
    required ServiceRequestStatus status,
    required int version,
    String? note,
  }) async {
    if (changeError != null) throw changeError!;
    changes.add((id: id, status: status, version: version, note: note));
    final d = ServiceRequestDetail.fromJson(
      detailJson(id: id, status: status.apiValue, version: version + 1, allowed: const []),
    );
    details[id] = d;
    return d;
  }
}

// ------------------------------------------------------------- realtime

class FakeRealtimeConnection implements RealtimeConnection {
  final _status = StreamController<RealtimeStatus>.broadcast();
  final _events = StreamController<ServiceRequestChangedEvent>.broadcast();
  final _connected = StreamController<void>.broadcast();
  RealtimeStatus _current = RealtimeStatus.disconnected;
  int starts = 0;
  int stops = 0;

  @override
  RealtimeStatus get status => _current;
  @override
  Stream<RealtimeStatus> get statusChanges => _status.stream;
  @override
  Stream<ServiceRequestChangedEvent> get serviceRequestChanged => _events.stream;
  @override
  Stream<void> get connected => _connected.stream;

  void _set(RealtimeStatus s) {
    _current = s;
    _status.add(s);
  }

  @override
  Future<void> start() async {
    starts++;
    _set(RealtimeStatus.connected);
  }

  @override
  Future<void> stop() async {
    stops++;
    _set(RealtimeStatus.disconnected);
  }

  void emitChanged(String id, {String change = 'statusChanged', String? status}) {
    _events.add(ServiceRequestChangedEvent(
      serviceRequestId: id,
      organizationId: orgId,
      change: change,
      status: status,
    ));
  }

  void emitReconnected() => _connected.add(null);

  @override
  Future<void> dispose() async {
    await _status.close();
    await _events.close();
    await _connected.close();
  }
}
