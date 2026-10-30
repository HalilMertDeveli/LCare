import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/iretry_policy.dart';
import 'package:signalr_netcore/signalr_client.dart';

enum RealtimeStatus { disconnected, connecting, connected }

/// `serviceRequestChanged` payload. A hint to re-fetch — never rendered.
class ServiceRequestChangedEvent {
  const ServiceRequestChangedEvent({
    required this.serviceRequestId,
    required this.organizationId,
    required this.change,
    this.status,
    this.version,
    this.occurredAt,
  });

  factory ServiceRequestChangedEvent.fromJson(Map<String, dynamic> json) =>
      ServiceRequestChangedEvent(
        serviceRequestId: json['serviceRequestId'] as String,
        organizationId: json['organizationId'] as String,
        change: json['change'] as String,
        status: json['status'] as String?,
        version: (json['version'] as num?)?.toInt(),
        occurredAt: json['occurredAt'] == null
            ? null
            : DateTime.tryParse(json['occurredAt'] as String),
      );

  final String serviceRequestId;
  final String organizationId;

  /// `created` | `statusChanged`
  final String change;
  final String? status;
  final int? version;
  final DateTime? occurredAt;
}

/// Transport-agnostic realtime connection (faked in tests).
abstract class RealtimeConnection {
  Stream<RealtimeStatus> get statusChanges;
  RealtimeStatus get status;
  Stream<ServiceRequestChangedEvent> get serviceRequestChanged;

  /// Emits after every successful (re)connect: events may have been missed.
  Stream<void> get connected;

  /// Idempotent: connects if not connected/connecting.
  Future<void> start();
  Future<void> stop();
  Future<void> dispose();
}

/// ASP.NET Core SignalR (`/hubs/notifications`, JSON protocol, WebSockets)
/// via `signalr_netcore`. The bearer token goes in the `access_token` query
/// string through `accessTokenFactory`.
class SignalRRealtimeConnection implements RealtimeConnection {
  SignalRRealtimeConnection({
    required this.hubUrl,
    required this.accessTokenFactory,
  });

  final String hubUrl;
  final Future<String?> Function() accessTokenFactory;

  final _status = StreamController<RealtimeStatus>.broadcast();
  final _events = StreamController<ServiceRequestChangedEvent>.broadcast();
  final _connected = StreamController<void>.broadcast();

  HubConnection? _hub;
  Timer? _retryTimer;
  int _attempt = 0;
  bool _wanted = false;
  RealtimeStatus _current = RealtimeStatus.disconnected;

  @override
  Stream<RealtimeStatus> get statusChanges => _status.stream;
  @override
  RealtimeStatus get status => _current;
  @override
  Stream<ServiceRequestChangedEvent> get serviceRequestChanged => _events.stream;
  @override
  Stream<void> get connected => _connected.stream;

  void _set(RealtimeStatus s) {
    if (_current == s || _status.isClosed) return;
    _current = s;
    _status.add(s);
  }

  HubConnection _build() {
    final hub = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            transport: HttpTransportType.WebSockets,
            accessTokenFactory: () async => (await accessTokenFactory()) ?? '',
            requestTimeout: 15000,
          ),
        )
        .withAutomaticReconnect(reconnectPolicy: _BackoffRetryPolicy())
        .build();

    hub.on('serviceRequestChanged', (args) {
      final payload = (args == null || args.isEmpty) ? null : args.first;
      if (payload is Map) {
        try {
          _events.add(ServiceRequestChangedEvent.fromJson(
            Map<String, dynamic>.from(payload),
          ));
        } catch (e) {
          debugPrint('realtime: ignored malformed serviceRequestChanged ($e)');
        }
      }
    });
    hub.onreconnecting(({error}) => _set(RealtimeStatus.connecting));
    hub.onreconnected(({connectionId}) {
      _set(RealtimeStatus.connected);
      _connected.add(null);
    });
    hub.onclose(({error}) {
      _set(RealtimeStatus.disconnected);
      // Automatic reconnect gave up (or server closed): keep trying while
      // signed in.
      if (_wanted) _scheduleRetry();
    });
    return hub;
  }

  @override
  Future<void> start() async {
    _wanted = true;
    final state = _hub?.state;
    if (state == HubConnectionState.Connected ||
        state == HubConnectionState.Connecting ||
        state == HubConnectionState.Reconnecting) {
      return;
    }
    _retryTimer?.cancel();
    _hub ??= _build();
    _set(RealtimeStatus.connecting);
    try {
      await _hub!.start();
      _attempt = 0;
      _set(RealtimeStatus.connected);
      _connected.add(null);
    } catch (e) {
      debugPrint('realtime: connect failed ($e)');
      _set(RealtimeStatus.disconnected);
      if (_wanted) _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    final seconds = min(30, 2 << min(_attempt, 4)); // 2,4,8,16,30…
    _attempt++;
    _retryTimer = Timer(Duration(seconds: seconds), () {
      if (_wanted) start();
    });
  }

  @override
  Future<void> stop() async {
    _wanted = false;
    _retryTimer?.cancel();
    final hub = _hub;
    _hub = null;
    _set(RealtimeStatus.disconnected);
    if (hub != null) {
      try {
        await hub.stop();
      } catch (_) {}
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _status.close();
    await _events.close();
    await _connected.close();
  }
}

/// Never gives up: 0s, 2s, 5s, 10s, then every 30s.
class _BackoffRetryPolicy implements IRetryPolicy {
  static const _delays = [0, 2000, 5000, 10000];

  @override
  int? nextRetryDelayInMilliseconds(RetryContext retryContext) {
    final n = retryContext.previousRetryCount;
    return n < _delays.length ? _delays[n] : 30000;
  }
}
