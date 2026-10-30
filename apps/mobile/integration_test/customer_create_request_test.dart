import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ledcare_mobile/core/realtime/realtime_connection.dart';
import 'package:ledcare_mobile/core/realtime/realtime_controller.dart';
import 'package:ledcare_mobile/core/router/app_router.dart';

import 'helpers.dart';

/// Real API (API_BASE_URL, default http://10.0.2.2:5080), real secure storage,
/// real SignalR. Run:
///   flutter test integration_test/customer_create_request_test.dart -d emulator-5554 \
///     --dart-define=LEDCARE_TEST_PASSWORD=...
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'customer logs in, creates a request through the UI and sees it in the list',
    skip: testPassword.isEmpty,
    (tester) async {
      final container = await startSignedOut(tester);

      await login(tester, 'musteri.a@ledcare.local');
      await pumpUntilFound(tester, find.byKey(const Key('requestList-customer')));

      // SignalR hub connects with the bearer token (access_token query).
      await pumpUntilFound(tester, find.byKey(const ValueKey('realtime-connected')),
          timeout: const Duration(seconds: 20));
      expect(container.read(realtimeControllerProvider), RealtimeStatus.connected);

      final events = <ServiceRequestChangedEvent>[];
      final sub = container
          .read(realtimeConnectionProvider)
          .serviceRequestChanged
          .listen(events.add);
      addTearDown(sub.cancel);

      final title = 'Mobil E2E ${DateTime.now().toUtc().toIso8601String()}';
      // ignore: avoid_print
      print('LEDCARE_CREATED_TITLE=$title');

      await tester.tap(find.byKey(const Key('newRequestButton')));
      await pumpUntilFound(tester, find.byKey(const Key('createRequestScreen')));
      await tester.enterText(find.byKey(const Key('titleField')), title);
      await tester.enterText(
        find.byKey(const Key('descriptionField')),
        'Entegrasyon testi: emülatörden oluşturulan talep. Sol alt modülde görüntü yok.',
      );
      await tester.tap(find.byKey(const Key('submitRequestButton')));

      // Lands on the server-returned detail.
      await pumpUntilFound(tester, find.byKey(const Key('requestDetailScreen')));
      await pumpUntilFound(tester, find.text(title));
      expect(find.text('Yeni'), findsWidgets);
      expect(find.byKey(const Key('cancelRequestButton')), findsOneWidget);

      // Back to the list: the new request is there (re-fetched from REST).
      container.read(routerProvider).go(Routes.customerRequests);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('requestDetailScreen')), findsNothing);
      final inList = find.descendant(
        of: find.byKey(const Key('requestListView')),
        matching: find.text(title),
      );
      await pumpUntilFound(tester, inList);
      expect(inList, findsOneWidget);

      // The owning customer receives the realtime hint for its own request.
      final end = DateTime.now().add(const Duration(seconds: 10));
      while (events.isEmpty && DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      // ignore: avoid_print
      print('LEDCARE_REALTIME_EVENTS=${events.map((e) => '${e.change}:${e.status}').join(',')}');
      expect(events.where((e) => e.change == 'created'), isNotEmpty,
          reason: 'serviceRequestChanged(created) expected over SignalR');
    },
  );
}
