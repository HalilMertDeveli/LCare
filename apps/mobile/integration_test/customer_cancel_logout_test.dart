import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ledcare_mobile/core/auth/token_storage.dart';
import 'package:ledcare_mobile/core/router/app_router.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'customer cancels own request, then logs out and tokens are cleared',
    skip: testPassword.isEmpty,
    (tester) async {
      final container = await startSignedOut(tester);
      await login(tester, 'musteri.a@ledcare.local');
      await pumpUntilFound(tester, find.byKey(const Key('requestList-customer')));

      await tester.tap(find.byKey(const Key('newRequestButton')));
      await pumpUntilFound(tester, find.byKey(const Key('createRequestScreen')));
      await tester.enterText(
          find.byKey(const Key('titleField')), 'Mobil iptal ${DateTime.now().toUtc().toIso8601String()}');
      await tester.enterText(find.byKey(const Key('descriptionField')), 'Entegrasyon testi: müşteri iptal akışı.');
      await tester.tap(find.byKey(const Key('submitRequestButton')));

      final cancel = find.byKey(const Key('cancelRequestButton'));
      await pumpUntilFound(tester, cancel);
      await tester.ensureVisible(cancel);
      await tester.tap(cancel);
      await pumpUntilFound(tester, find.byKey(const Key('confirmTransition')));
      await tester.tap(find.byKey(const Key('confirmTransition')));

      final status = find.byKey(const Key('detailStatus'));
      await pumpUntilFound(tester, find.descendant(of: status, matching: find.text('İptal Edildi')));
      await pumpUntilFound(tester, find.byKey(const Key('requestDetailScreen')));
      expect(cancel, findsNothing);

      container.read(routerProvider).go(Routes.customerProfile);
      await pumpUntilFound(tester, find.byKey(const Key('logoutButton')));
      await tester.tap(find.byKey(const Key('logoutButton')));
      await pumpUntilFound(tester, find.byKey(const Key('loginScreen')));
      expect(await SecureTokenStore().read(), isNull);
    },
  );

  testWidgets(
    'technician signs in to the technician shell with an honest empty state',
    skip: testPassword.isEmpty,
    (tester) async {
      await startSignedOut(tester);
      await login(tester, 'saha.teknisyen@ledcare.local');
      await pumpUntilFound(tester, find.byKey(const Key('technicianEmpty')));
    },
  );
}
