import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

/// Title of an existing request in status `New` (e.g. the one created by
/// customer_create_request_test). Skipped when not supplied.
const targetTitle = String.fromEnvironment('LEDCARE_TARGET_TITLE');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'admin opens a request by title and moves it to InReview',
    skip: testPassword.isEmpty || targetTitle.isEmpty,
    (tester) async {
      await startSignedOut(tester);

      await login(tester, 'admin@ledcare.local');
      await pumpUntilFound(tester, find.byKey(const Key('requestList-staff')));

      // Narrow to "Yeni" so the target is near the top, then open it.
      await tester.tap(find.byKey(const Key('filter-New')));
      final item = find.text(targetTitle);
      await pumpUntilFound(tester, item);
      await tester.ensureVisible(item);
      await tester.tap(item);

      await pumpUntilFound(tester, find.byKey(const Key('requestDetailScreen')));
      await pumpUntilFound(tester, find.byKey(const Key('transition-InReview')));
      // Only server-allowed transitions are rendered.
      expect(find.byKey(const Key('transition-Closed')), findsNothing);

      await tester.tap(find.byKey(const Key('transition-InReview')));
      await pumpUntilFound(tester, find.byKey(const Key('transitionNote')));
      await tester.enterText(find.byKey(const Key('transitionNote')), 'Mobil entegrasyon testi');
      await tester.tap(find.byKey(const Key('confirmTransition')));

      // After reload from REST the InReview action is gone and history shows the note.
      await pumpUntilFound(tester, find.text('Mobil entegrasyon testi'));
      await pumpUntilFound(tester, find.byKey(const Key('transition-WaitingForCustomer')));
      expect(find.byKey(const Key('transition-InReview')), findsNothing);
      expect(find.text('İnceleniyor'), findsWidgets);
    },
  );
}
