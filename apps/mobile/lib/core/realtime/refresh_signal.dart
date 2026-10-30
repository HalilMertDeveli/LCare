import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Monotonic counter bumped whenever server data may have changed
/// (realtime hint, hub reconnect, app resume, local mutation).
///
/// Data providers `ref.watch` it, so a bump invalidates every live list and
/// detail provider and they re-fetch from REST. Realtime events never carry
/// data into the UI directly.
final refreshSignalProvider =
    NotifierProvider<RefreshSignal, int>(RefreshSignal.new);

class RefreshSignal extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}
