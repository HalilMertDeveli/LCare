import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledcare_mobile/app.dart';
import 'package:ledcare_mobile/core/auth/auth_controller.dart';
import 'package:ledcare_mobile/core/auth/auth_models.dart';
import 'package:ledcare_mobile/core/auth/token_storage.dart';
import 'package:ledcare_mobile/core/network/api_client.dart';
import 'package:ledcare_mobile/core/network/api_exception.dart';
import 'package:ledcare_mobile/core/network/network_providers.dart';

import 'helpers/fakes.dart';

void main() {
  late InMemoryTokenStore store;
  late FakeAdapter adapter;

  ProviderContainer makeContainer() {
    final c = ProviderContainer(retry: noRetry, overrides: [
      tokenStoreProvider.overrideWithValue(store),
      apiClientProvider.overrideWith((ref) => ApiClient(
            baseUrl: 'http://api.test',
            tokenStore: store,
            onSessionExpired: () => ref.read(authControllerProvider.notifier).sessionExpired(),
            adapter: adapter,
          )),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  Future<AuthState> settled(ProviderContainer c) async {
    c.read(authControllerProvider);
    for (var i = 0; i < 50 && c.read(authControllerProvider) is AuthRestoring; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    return c.read(authControllerProvider);
  }

  test('cold start without stored tokens → signed out', () async {
    store = InMemoryTokenStore();
    adapter = FakeAdapter((_) => const FakeResponse(500));
    expect(await settled(makeContainer()), isA<AuthSignedOut>());
    expect(adapter.requests, isEmpty);
  });

  test('cold start with stored tokens restores the session via /api/me', () async {
    store = InMemoryTokenStore(const AuthTokens(accessToken: 'a', refreshToken: 'r'));
    adapter = FakeAdapter((r) => FakeResponse(200, staffMe));
    final state = await settled(makeContainer());
    expect(state, isA<AuthSignedIn>());
    expect((state as AuthSignedIn).me.shell, AppShell.admin);
  });

  test('cold start with a dead refresh token → signed out (expired), storage cleared', () async {
    store = InMemoryTokenStore(const AuthTokens(accessToken: 'a', refreshToken: 'r'));
    adapter = FakeAdapter((_) => const FakeResponse(401));
    final state = await settled(makeContainer());
    expect(state, isA<AuthSignedOut>().having((s) => s.sessionExpired, 'expired', true));
    expect(store.current, isNull);
  });

  test('cold start while offline keeps tokens and offers retry', () async {
    store = InMemoryTokenStore(const AuthTokens(accessToken: 'a', refreshToken: 'r'));
    adapter = FakeAdapter((_) => network);
    expect(await settled(makeContainer()), isA<AuthRestoreFailed>());
    expect(store.current, isNotNull);
  });

  test('login → signed in with tokens stored; logout → signed out and cleared', () async {
    store = InMemoryTokenStore();
    adapter = FakeAdapter((r) => switch (r.path) {
          '/api/auth/login' => FakeResponse(200, tokenJson('acc', 'ref')),
          '/api/me' => FakeResponse(200, customerMe),
          _ => const FakeResponse(404),
        });
    final c = makeContainer();
    await settled(c);

    await c.read(authControllerProvider.notifier).login(' musteri.a@ledcare.local ', 'pw');
    final state = c.read(authControllerProvider);
    expect(state, isA<AuthSignedIn>());
    expect((state as AuthSignedIn).me.shell, AppShell.customer);
    expect(store.current!.accessToken, 'acc');
    expect(store.current!.accessExpiresAt, isNotNull);
    expect(adapter.to('/api/auth/login').single.data, {
      'email': 'musteri.a@ledcare.local',
      'password': 'pw',
    });
    expect(adapter.to('/api/auth/login').single.uri.queryParameters, isEmpty,
        reason: 'bearer mode: no useCookies');

    await c.read(authControllerProvider.notifier).logout();
    expect(c.read(authControllerProvider), isA<AuthSignedOut>());
    expect(store.current, isNull);
  });

  test('wrong password → ApiException(unauthorized), still signed out', () async {
    store = InMemoryTokenStore();
    adapter = FakeAdapter((_) => const FakeResponse(401));
    final c = makeContainer();
    await settled(c);
    await expectLater(
      c.read(authControllerProvider.notifier).login('a@b.c', 'bad'),
      throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.unauthorized)),
    );
    expect(c.read(authControllerProvider), isA<AuthSignedOut>());
    expect(adapter.to('/api/auth/refresh'), isEmpty);
  });

  test('refresh failure mid-session signs the user out', () async {
    store = InMemoryTokenStore(const AuthTokens(accessToken: 'a', refreshToken: 'r'));
    var meOk = true;
    adapter = FakeAdapter((r) {
      if (r.path == '/api/me' && meOk) return FakeResponse(200, customerMe);
      return const FakeResponse(401);
    });
    final c = makeContainer();
    expect(await settled(c), isA<AuthSignedIn>());

    meOk = false;
    await expectLater(c.read(apiClientProvider).dio.get<dynamic>('/api/service-requests'),
        throwsA(anything));
    expect(c.read(authControllerProvider),
        isA<AuthSignedOut>().having((s) => s.sessionExpired, 'expired', true));
    expect(store.current, isNull);
  });

  group('shell selection from /api/me', () {
    test('staff', () {
      expect(MeResponse.fromJson(staffMe).shell, AppShell.admin);
      expect(MeResponse.fromJson(meJson(roles: ['Dispatcher'])).shell, AppShell.admin);
      expect(MeResponse.fromJson(meJson(platformRoles: ['PlatformSuperAdmin'], roles: []))
          .shell, AppShell.admin);
    });
    test('customer', () => expect(MeResponse.fromJson(customerMe).shell, AppShell.customer));
    test('technician only', () {
      expect(MeResponse.fromJson(technicianMe).shell, AppShell.technician);
      expect(MeResponse.fromJson(meJson(roles: ['RemoteSupportTechnician'])).shell,
          AppShell.technician);
    });
    test('no roles', () => expect(MeResponse.fromJson(meJson(roles: [])).shell, AppShell.none));
  });
}
