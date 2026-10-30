import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledcare_mobile/core/auth/token_storage.dart';
import 'package:ledcare_mobile/core/network/api_client.dart';
import 'package:ledcare_mobile/core/network/api_exception.dart';

import 'helpers/fakes.dart';

void main() {
  late InMemoryTokenStore store;
  late int expiredCalls;

  ApiClient client(FakeAdapter adapter) => ApiClient(
        baseUrl: 'http://api.test',
        tokenStore: store,
        onSessionExpired: () => expiredCalls++,
        adapter: adapter,
      );

  setUp(() {
    store = InMemoryTokenStore(const AuthTokens(accessToken: 'old', refreshToken: 'r-old'));
    expiredCalls = 0;
  });

  test('attaches the bearer access token', () async {
    final adapter = FakeAdapter((_) => FakeResponse(200, meJson()));
    await client(adapter).dio.get<dynamic>('/api/me');
    expect(adapter.requests.single.headers['Authorization'], 'Bearer old');
  });

  test('login/refresh calls do not carry a bearer token', () async {
    final adapter = FakeAdapter((_) => FakeResponse(200, tokenJson('a', 'r')));
    await client(adapter).dio.post<dynamic>(
          '/api/auth/login',
          data: {'email': 'x@y.z', 'password': 'p'},
          options: Options(extra: {kSkipAuth: true}),
        );
    expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse);
  });

  test('concurrent 401s trigger a single refresh, then each request is retried once',
      () async {
    final refreshGate = Completer<void>();
    final adapter = FakeAdapter((r) async {
      if (r.path == '/api/auth/refresh') {
        await refreshGate.future;
        expect(r.data, {'refreshToken': 'r-old'});
        return FakeResponse(200, tokenJson('new', 'r-new'));
      }
      return r.headers['Authorization'] == 'Bearer new'
          ? FakeResponse(200, {'ok': r.path})
          : const FakeResponse(401);
    });
    final api = client(adapter);

    final futures = [
      api.dio.get<dynamic>('/api/service-requests'),
      api.dio.get<dynamic>('/api/me'),
      api.dio.get<dynamic>('/api/service-requests/1'),
    ];
    await Future<void>.delayed(const Duration(milliseconds: 20));
    refreshGate.complete();
    final responses = await Future.wait(futures);

    expect(responses.map((r) => r.statusCode), everyElement(200));
    expect(adapter.to('/api/auth/refresh'), hasLength(1));
    expect(adapter.to('/api/me'), hasLength(2)); // original + one retry
    expect(adapter.to('/api/me').last.headers['Authorization'], 'Bearer new');
    expect(store.current!.accessToken, 'new');
    expect(store.current!.refreshToken, 'r-new'); // rotated
    expect(expiredCalls, 0);
  });

  test('a retried request that is still 401 is not refreshed again', () async {
    final adapter = FakeAdapter((r) => r.path == '/api/auth/refresh'
        ? FakeResponse(200, tokenJson('new', 'r-new'))
        : const FakeResponse(401));
    await expectLater(
      client(adapter).dio.get<dynamic>('/api/me'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.to('/api/auth/refresh'), hasLength(1));
    expect(adapter.to('/api/me'), hasLength(2));
  });

  test('failed refresh clears the session and signals logout', () async {
    final adapter = FakeAdapter((r) => const FakeResponse(401));
    final api = client(adapter);

    await expectLater(
      guardApi(() => api.dio.get<dynamic>('/api/me')),
      throwsA(isA<ApiException>()
          .having((e) => e.kind, 'kind', ApiErrorKind.unauthorized)),
    );
    expect(adapter.to('/api/auth/refresh'), hasLength(1));
    expect(store.current, isNull);
    expect(expiredCalls, 1);
  });

  test('network failure during refresh keeps the session', () async {
    final adapter = FakeAdapter((r) =>
        r.path == '/api/auth/refresh' ? network : const FakeResponse(401));
    await expectLater(client(adapter).dio.get<dynamic>('/api/me'), throwsA(isA<DioException>()));
    expect(store.current, isNotNull);
    expect(expiredCalls, 0);
  });

  test('problem+json validation errors are normalised to camelCase keys', () async {
    final adapter = FakeAdapter((_) => const FakeResponse(400, {
          'title': 'One or more validation errors occurred.',
          'status': 400,
          'errors': {
            'Title': ['too short'],
            'Description': ['too short'],
          },
        }));
    try {
      await guardApi(() => client(adapter).dio.post<dynamic>('/api/service-requests'));
      fail('expected ApiException');
    } on ApiException catch (e) {
      expect(e.kind, ApiErrorKind.validation);
      expect(e.fieldErrors.keys, containsAll(['title', 'description']));
    }
  });

  test('current API shape: Turkish title, camelCase keys pass through', () async {
    final adapter = FakeAdapter((_) => const FakeResponse(400, {
          'title': 'Girilen bilgiler geçersiz',
          'status': 400,
          'errors': {
            'note': ['Not en fazla 1000 karakter olabilir.'],
          },
        }));
    try {
      await guardApi(() => client(adapter).dio.post<dynamic>('/api/service-requests/x/status'));
      fail('expected ApiException');
    } on ApiException catch (e) {
      expect(e.title, 'Girilen bilgiler geçersiz');
      expect(e.fieldErrors['note'], ['Not en fazla 1000 karakter olabilir.']);
    }
  });

  test('freshAccessToken refreshes when the token is about to expire', () async {
    store = InMemoryTokenStore(AuthTokens(
      accessToken: 'old',
      refreshToken: 'r-old',
      accessExpiresAt: DateTime.now().toUtc().add(const Duration(seconds: 10)),
    ));
    final adapter = FakeAdapter((_) => FakeResponse(200, tokenJson('new', 'r-new')));
    expect(await client(adapter).freshAccessToken(), 'new');

    store = InMemoryTokenStore(AuthTokens(
      accessToken: 'valid',
      refreshToken: 'r',
      accessExpiresAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
    ));
    final idle = FakeAdapter((_) => const FakeResponse(500));
    expect(await client(idle).freshAccessToken(), 'valid');
    expect(idle.requests, isEmpty);
  });
}
