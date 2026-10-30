import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../network/network_providers.dart';
import 'realtime_connection.dart';
import 'refresh_signal.dart';

final realtimeConnectionProvider = Provider<RealtimeConnection>((ref) {
  final config = ref.watch(appConfigProvider);
  final api = ref.watch(apiClientProvider);
  final connection = SignalRRealtimeConnection(
    hubUrl: config.notificationsHubUrl,
    accessTokenFactory: api.freshAccessToken,
  );
  ref.onDispose(connection.dispose);
  return connection;
});

/// Owns the hub lifecycle: connected while signed in, stopped when signed
/// out. Every `serviceRequestChanged` event, every (re)connect and every app
/// resume bumps [refreshSignalProvider] so visible data re-fetches via REST.
final realtimeControllerProvider =
    NotifierProvider<RealtimeController, RealtimeStatus>(RealtimeController.new);

class RealtimeController extends Notifier<RealtimeStatus> {
  /// Coalesces bursts of events into one re-fetch.
  static const debounce = Duration(milliseconds: 300);

  Timer? _debounce;

  @override
  RealtimeStatus build() {
    final connection = ref.watch(realtimeConnectionProvider);
    final subs = <StreamSubscription<Object?>>[
      connection.statusChanges.listen((s) => state = s),
      connection.serviceRequestChanged.listen((_) => requestRefresh()),
      connection.connected.listen((_) => requestRefresh()),
    ];
    ref.onDispose(() {
      _debounce?.cancel();
      for (final s in subs) {
        s.cancel();
      }
    });

    ref.listen<AuthState>(
      authControllerProvider,
      (_, next) => _syncWithAuth(connection, next),
      fireImmediately: true,
    );
    return connection.status;
  }

  void _syncWithAuth(RealtimeConnection connection, AuthState auth) {
    scheduleMicrotask(() {
      if (auth is AuthSignedIn) {
        connection.start();
      } else {
        connection.stop();
      }
    });
  }

  void requestRefresh() {
    _debounce?.cancel();
    _debounce = Timer(debounce, () => ref.read(refreshSignalProvider.notifier).bump());
  }

  /// Called from `AppLifecycleListener.onResume`.
  void onAppResumed() {
    if (ref.read(authControllerProvider) is! AuthSignedIn) return;
    requestRefresh();
    ref.read(realtimeConnectionProvider).start();
  }
}
