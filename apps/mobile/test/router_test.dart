import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledcare_mobile/core/auth/auth_controller.dart';
import 'package:ledcare_mobile/core/auth/auth_models.dart';
import 'package:ledcare_mobile/core/network/api_exception.dart';
import 'package:ledcare_mobile/core/router/app_router.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

void main() {
  group('authRedirect (pure guard)', () {
    final customer = AuthSignedIn(MeResponse.fromJson(customerMe));
    final staff = AuthSignedIn(MeResponse.fromJson(staffMe));
    final tech = AuthSignedIn(MeResponse.fromJson(technicianMe));

    test('restoring → splash', () {
      expect(authRedirect(const AuthRestoring(), '/admin/requests'), Routes.splash);
      expect(authRedirect(const AuthRestoring(), Routes.splash), isNull);
      expect(authRedirect(const AuthRestoreFailed(ApiException(kind: ApiErrorKind.network)),
          '/customer/requests'), Routes.splash);
    });

    test('unauthenticated → login for every protected route', () {
      for (final loc in ['/splash', '/customer/requests', '/admin/requests/x', '/technician/jobs']) {
        expect(authRedirect(const AuthSignedOut(), loc), Routes.login);
      }
      expect(authRedirect(const AuthSignedOut(), Routes.login), isNull);
    });

    test('customer is kept inside the customer shell', () {
      expect(authRedirect(customer, Routes.login), Routes.customerRequests);
      expect(authRedirect(customer, '/admin/requests'), Routes.customerRequests);
      expect(authRedirect(customer, '/customer/requests/abc'), isNull);
      expect(authRedirect(customer, '/customerx'), Routes.customerRequests);
    });

    test('staff is kept inside the admin shell', () {
      expect(authRedirect(staff, Routes.splash), Routes.adminRequests);
      expect(authRedirect(staff, '/customer/requests/new'), Routes.adminRequests);
      expect(authRedirect(staff, '/admin/requests/abc'), isNull);
    });

    test('technician → technician shell', () {
      expect(authRedirect(tech, Routes.login), Routes.technicianJobs);
      expect(authRedirect(tech, '/admin/requests'), Routes.technicianJobs);
    });
  });

  group('router + app bootstrap', () {
    testWidgets('no stored session → login screen', (tester) async {
      await pumpApp(tester);
      expect(find.byKey(const Key('loginScreen')), findsOneWidget);
      expect(find.text('Giriş yap'), findsWidgets);
    });

    testWidgets('stored customer session → customer shell with my requests', (tester) async {
      await pumpApp(tester, tokens: storedTokens, me: customerMe);
      expect(find.byKey(const Key('shell-customer')), findsOneWidget);
      expect(find.byKey(const Key('requestList-customer')), findsOneWidget);
      expect(find.text('Taleplerim'), findsWidgets);
      expect(find.byKey(const Key('newRequestButton')), findsOneWidget);
    });

    testWidgets('stored staff session → admin shell with filters', (tester) async {
      await pumpApp(tester, tokens: storedTokens, me: staffMe);
      expect(find.byKey(const Key('shell-admin')), findsOneWidget);
      expect(find.byKey(const Key('requestList-staff')), findsOneWidget);
      expect(find.byKey(const Key('filter-all')), findsOneWidget);
      expect(find.byKey(const Key('newRequestButton')), findsNothing);
    });

    testWidgets('technician-only → honest empty state', (tester) async {
      final app = await pumpApp(tester, tokens: storedTokens, me: technicianMe);
      expect(find.byKey(const Key('shell-technician')), findsOneWidget);
      expect(find.text('Size atanmış iş bulunmuyor'), findsOneWidget);
      expect(app.repo.listCalls, 0, reason: 'no fake data, no list call');
    });

    testWidgets('login through the UI routes a customer to the customer shell', (tester) async {
      await pumpApp(tester, handler: (r) => switch (r.path) {
            '/api/auth/login' => FakeResponse(200, tokenJson('acc', 'ref')),
            '/api/me' => FakeResponse(200, customerMe),
            _ => const FakeResponse(404),
          });
      await tester.enterText(find.byKey(const Key('emailField')), 'musteri.a@ledcare.local');
      await tester.enterText(find.byKey(const Key('passwordField')), 'secret');
      await tester.tap(find.byKey(const Key('loginButton')));
      await settle(tester);
      expect(find.byKey(const Key('shell-customer')), findsOneWidget);
    });

    testWidgets('login with wrong password shows an error and stays on login', (tester) async {
      await pumpApp(tester, handler: (_) => const FakeResponse(401));
      await tester.enterText(find.byKey(const Key('emailField')), 'musteri.a@ledcare.local');
      await tester.enterText(find.byKey(const Key('passwordField')), 'wrong');
      await tester.tap(find.byKey(const Key('loginButton')));
      await settle(tester);
      expect(find.byKey(const Key('loginError')), findsOneWidget);
      expect(find.text('E-posta veya şifre hatalı.'), findsOneWidget);
    });

    testWidgets('logout from profile returns to login and stops realtime', (tester) async {
      final app = await pumpApp(tester, tokens: storedTokens, me: staffMe);
      expect(app.realtime.starts, greaterThan(0));
      await tester.tap(find.byKey(const Key('nav-1')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('logoutButton')));
      await settle(tester);
      expect(find.byKey(const Key('loginScreen')), findsOneWidget);
      expect(app.store.current, isNull);
      expect(app.realtime.stops, greaterThan(0));
    });
  });
}
