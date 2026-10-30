import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

/// Cross-platform step driven by tests/integration/cross-platform.mjs: the customer keeps
/// the detail screen open and must see the status change made on the web, with no user
/// interaction (SignalR hint + REST re-fetch).
const targetTitle = String.fromEnvironment('LEDCARE_TARGET_TITLE');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'customer detail screen shows a status changed on another platform',
    skip: testPassword.isEmpty || targetTitle.isEmpty,
    (tester) async {
      await startSignedOut(tester);
      await login(tester, 'musteri.a@ledcare.local');
      await pumpUntilFound(tester, find.byKey(const Key('requestList-customer')));
      await pumpUntilFound(tester, find.byKey(const ValueKey('realtime-connected')),
          timeout: const Duration(seconds: 20));

      final item = find.text(targetTitle);
      await pumpUntilFound(tester, item);
      await tester.ensureVisible(item);
      await tester.tap(item);
      await pumpUntilFound(tester, find.byKey(const Key('requestDetailScreen')));

      final status = find.byKey(const Key('detailStatus'));
      await pumpUntilFound(tester, status);
      expect(
        find.descendant(of: status, matching: find.text('Yeni')),
        findsOneWidget,
      );

      // ignore: avoid_print
      print('LEDCARE_READY');

      await pumpUntilFound(
        tester,
        find.descendant(of: status, matching: find.text('İnceleniyor')),
        timeout: const Duration(minutes: 4),
      );
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
