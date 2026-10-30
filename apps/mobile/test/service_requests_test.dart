import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledcare_mobile/core/network/api_exception.dart';
import 'package:ledcare_mobile/core/router/app_router.dart';
import 'package:ledcare_mobile/features/service_requests/data/service_request_models.dart';
import 'package:ledcare_mobile/features/service_requests/presentation/create_request_screen.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

const reqId = '01a18ba6-ca33-7417-8680-a2dd8ed9791b';

void main() {
  group('DTOs', () {
    test('detail parses enums, nullable history fields and uint version', () {
      final d = ServiceRequestDetail.fromJson(detailJson(status: 'InReview', version: 788));
      expect(d.status, ServiceRequestStatus.inReview);
      expect(d.version, 788);
      expect(d.history.first.fromStatus, isNull);
      expect(d.history.last.fromStatus, ServiceRequestStatus.newRequest);
      expect(d.allowedTransitions, contains(ServiceRequestStatus.cancelled));
    });
  });

  group('request form validation', () {
    test('title 5–150, description 10–4000 (trimmed)', () {
      expect(RequestValidation.titleValid('abcd'), isFalse);
      expect(RequestValidation.titleValid('   abcd   '), isFalse);
      expect(RequestValidation.titleValid('abcde'), isTrue);
      expect(RequestValidation.titleValid('a' * 150), isTrue);
      expect(RequestValidation.titleValid('a' * 151), isFalse);
      expect(RequestValidation.descriptionValid('123456789'), isFalse);
      expect(RequestValidation.descriptionValid('1234567890'), isTrue);
      expect(RequestValidation.descriptionValid('a' * 4001), isFalse);
    });

    testWidgets('empty submit shows both client errors and sends nothing', (tester) async {
      final app = await pumpApp(tester, tokens: storedTokens, me: customerMe);
      await tester.tap(find.byKey(const Key('newRequestButton')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('submitRequestButton')));
      await tester.pump();
      expect(find.text('Başlık 5 ile 150 karakter arasında olmalı.'), findsOneWidget);
      expect(find.text('Açıklama 10 ile 4000 karakter arasında olmalı.'), findsOneWidget);
      expect(app.repo.created, isEmpty);
    });

    testWidgets('server validation errors are shown under the fields', (tester) async {
      final repo = FakeServiceRequestRepository()
        ..createError = const ApiException(
          kind: ApiErrorKind.validation,
          statusCode: 400,
          fieldErrors: {
            'title': ['Sunucu: başlık geçersiz'],
          },
        );
      await pumpApp(tester, tokens: storedTokens, me: customerMe, repo: repo);
      await tester.tap(find.byKey(const Key('newRequestButton')));
      await settle(tester);
      await tester.enterText(find.byKey(const Key('titleField')), 'Ekran yanmıyor');
      await tester.enterText(find.byKey(const Key('descriptionField')), 'Sol alt modül tamamen kapalı.');
      await tester.tap(find.byKey(const Key('submitRequestButton')));
      await settle(tester);
      expect(find.text('Sunucu: başlık geçersiz'), findsOneWidget);
      expect(find.byKey(const Key('createRequestScreen')), findsOneWidget);
    });

    testWidgets('valid submit creates, opens the detail and refreshes the list', (tester) async {
      final app = await pumpApp(tester, tokens: storedTokens, me: customerMe);
      final listCallsBefore = app.repo.listCalls;
      await tester.tap(find.byKey(const Key('newRequestButton')));
      await settle(tester);
      await tester.enterText(find.byKey(const Key('titleField')), '  Ekran yanmıyor  ');
      await tester.enterText(find.byKey(const Key('descriptionField')), 'Sol alt modül tamamen kapalı.');
      await tester.tap(find.byKey(const Key('submitRequestButton')));
      await settle(tester);
      expect(app.repo.created.single.title, 'Ekran yanmıyor');
      expect(find.byKey(const Key('requestDetailScreen')), findsOneWidget);
      expect(find.byKey(const Key('cancelRequestButton')), findsOneWidget);

      // tester.pageBack() looks for package:flutter/material's BackButton;
      // the app uses material_ui, so pop through the router instead.
      app.container.read(routerProvider).pop();
      await settle(tester);
      expect(find.text('Ekran yanmıyor'), findsOneWidget);
      expect(app.repo.listCalls, greaterThan(listCallsBefore));
    });
  });

  group('list and detail rendering', () {
    testWidgets('customer list shows reference code, title and Turkish status', (tester) async {
      await pumpApp(tester, tokens: storedTokens, me: customerMe);
      expect(find.text('LC-000001'), findsOneWidget);
      expect(find.text('Ekranda ölü pikseller'), findsOneWidget);
      expect(find.text('Yeni'), findsOneWidget);
    });

    testWidgets('empty list shows an empty state, errors show retry', (tester) async {
      final repo = FakeServiceRequestRepository(items: []);
      await pumpApp(tester, tokens: storedTokens, me: customerMe, repo: repo);
      expect(find.byKey(const Key('emptyRequests')), findsOneWidget);
    });

    testWidgets('list error → retry button re-fetches', (tester) async {
      final repo = _FailingOnceRepository();
      await pumpApp(tester, tokens: storedTokens, me: customerMe, repo: repo);
      expect(find.text('Sunucuya ulaşılamadı. Bağlantınızı kontrol edin.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('retryButton')));
      await settle(tester);
      expect(find.text('Ekranda ölü pikseller'), findsOneWidget);
    });

    testWidgets('customer detail: history + cancel only when allowed', (tester) async {
      await pumpApp(tester, tokens: storedTokens, me: customerMe);
      await tester.tap(find.text('Ekranda ölü pikseller'));
      await settle(tester);
      expect(find.byKey(const Key('detailTitle')), findsOneWidget);
      expect(find.text('Sol alt modülde ölü pikseller var.'), findsOneWidget);
      expect(find.text('Talep oluşturuldu'), findsOneWidget);
      expect(find.byKey(const Key('cancelRequestButton')), findsOneWidget);
      // Customers never see staff transition buttons.
      expect(find.byKey(const Key('transition-InReview')), findsNothing);
    });

    testWidgets('customer detail without Cancelled in allowedTransitions hides cancel',
        (tester) async {
      final repo = FakeServiceRequestRepository(details: {
        reqId: ServiceRequestDetail.fromJson(
            detailJson(status: 'InProgress', allowed: const [])),
      });
      await pumpApp(tester, tokens: storedTokens, me: customerMe, repo: repo);
      await tester.tap(find.text('Ekranda ölü pikseller'));
      await settle(tester);
      expect(find.byKey(const Key('cancelRequestButton')), findsNothing);
    });

    testWidgets('staff detail renders exactly the allowed transitions and sends version',
        (tester) async {
      final app = await pumpApp(tester, tokens: storedTokens, me: staffMe);
      await tester.tap(find.text('Ekranda ölü pikseller'));
      await settle(tester);
      expect(find.byKey(const Key('transition-InReview')), findsOneWidget);
      expect(find.byKey(const Key('transition-InProgress')), findsOneWidget);
      expect(find.byKey(const Key('transition-Cancelled')), findsOneWidget);
      expect(find.byKey(const Key('transition-Resolved')), findsNothing);
      expect(find.byKey(const Key('transition-Closed')), findsNothing);

      await tester.tap(find.byKey(const Key('transition-InReview')));
      await settle(tester);
      await tester.enterText(find.byKey(const Key('transitionNote')), 'Kontrol ediliyor');
      await tester.tap(find.byKey(const Key('confirmTransition')));
      await settle(tester);

      final change = app.repo.changes.single;
      expect(change.status, ServiceRequestStatus.inReview);
      expect(change.version, 7);
      expect(change.note, 'Kontrol ediliyor');
      // Reloaded from the (fake) server: new status, no more actions.
      expect(find.byKey(const Key('noActions')), findsOneWidget);
    });

    testWidgets('409 shows "Kayıt güncel değil" and reloads the detail', (tester) async {
      final repo = FakeServiceRequestRepository()
        ..changeError = const ApiException(kind: ApiErrorKind.conflict, statusCode: 409);
      final app = await pumpApp(tester, tokens: storedTokens, me: staffMe, repo: repo);
      await tester.tap(find.text('Ekranda ölü pikseller'));
      await settle(tester);
      final getsBefore = app.repo.getCalls;

      await tester.tap(find.byKey(const Key('transition-InProgress')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('confirmTransition')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Kayıt güncel değil'), findsOneWidget);
      await settle(tester);
      expect(app.repo.getCalls, greaterThan(getsBefore));
    });

    testWidgets('staff status filter chip queries the API with that status', (tester) async {
      final app = await pumpApp(tester, tokens: storedTokens, me: staffMe);
      await tester.tap(find.byKey(const Key('filter-InReview')));
      await settle(tester);
      expect(app.repo.listStatuses.last, ServiceRequestStatus.inReview);
      expect(find.byKey(const Key('emptyRequests')), findsOneWidget);
    });
  });
}

class _FailingOnceRepository extends FakeServiceRequestRepository {
  bool _failed = false;

  @override
  Future<PagedResult<ServiceRequestSummary>> list({
    ServiceRequestStatus? status,
    int page = 1,
    int pageSize = 50,
  }) {
    if (!_failed) {
      _failed = true;
      throw const ApiException(kind: ApiErrorKind.network);
    }
    return super.list(status: status, page: page, pageSize: pageSize);
  }
}
