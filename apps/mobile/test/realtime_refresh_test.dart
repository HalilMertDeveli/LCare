import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledcare_mobile/core/realtime/realtime_connection.dart';
import 'package:ledcare_mobile/core/realtime/realtime_controller.dart';
import 'package:ledcare_mobile/features/service_requests/data/service_request_models.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

void main() {
  testWidgets('serviceRequestChanged → list re-fetched from REST and UI updated',
      (tester) async {
    final app = await pumpApp(tester, tokens: storedTokens, me: staffMe);
    expect(app.container.read(realtimeControllerProvider), RealtimeStatus.connected);
    expect(find.byKey(const ValueKey('realtime-connected')), findsOneWidget);
    final before = app.repo.listCalls;

    // Server-side change; the event itself carries no data we render.
    app.repo.items = [
      ServiceRequestSummary.fromJson(summaryJson(id: 'x2', ref: 'LC-000002', title: 'Yeni arıza')),
      ...app.repo.items,
    ];
    app.realtime.emitChanged('x2', change: 'created', status: 'New');
    await settle(tester);

    expect(app.repo.listCalls, before + 1);
    expect(find.text('Yeni arıza'), findsOneWidget);
  });

  testWidgets('a burst of events is coalesced into one re-fetch', (tester) async {
    final app = await pumpApp(tester, tokens: storedTokens, me: staffMe);
    final before = app.repo.listCalls;
    for (var i = 0; i < 5; i++) {
      app.realtime.emitChanged('id-$i');
    }
    await settle(tester);
    expect(app.repo.listCalls, before + 1);
  });

  testWidgets('reconnect and app resume both trigger a re-fetch', (tester) async {
    final app = await pumpApp(tester, tokens: storedTokens, me: customerMe);
    var before = app.repo.listCalls;
    app.realtime.emitReconnected();
    await settle(tester);
    expect(app.repo.listCalls, before + 1);

    before = app.repo.listCalls;
    final startsBefore = app.realtime.starts;
    app.container.read(realtimeControllerProvider.notifier).onAppResumed();
    await settle(tester);
    expect(app.repo.listCalls, before + 1);
    expect(app.realtime.starts, startsBefore + 1);
  });

  testWidgets('open detail is re-fetched on an event', (tester) async {
    final app = await pumpApp(tester, tokens: storedTokens, me: staffMe);
    await tester.tap(find.text('Ekranda ölü pikseller'));
    await settle(tester);
    final before = app.repo.getCalls;
    app.realtime.emitChanged('01a18ba6-ca33-7417-8680-a2dd8ed9791b');
    await settle(tester);
    expect(app.repo.getCalls, before + 1);
  });
}
