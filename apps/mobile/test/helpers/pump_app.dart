import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledcare_mobile/app.dart';
import 'package:ledcare_mobile/core/auth/auth_controller.dart';
import 'package:ledcare_mobile/core/auth/token_storage.dart';
import 'package:ledcare_mobile/core/network/api_client.dart';
import 'package:ledcare_mobile/core/network/network_providers.dart';
import 'package:ledcare_mobile/core/realtime/realtime_controller.dart';
import 'package:ledcare_mobile/features/service_requests/data/service_request_providers.dart';
import 'package:ledcare_mobile/features/service_requests/data/service_request_repository.dart';

import 'fakes.dart';

class TestApp {
  TestApp(this.container, this.adapter, this.store, this.repo, this.realtime);

  final ProviderContainer container;
  final FakeAdapter adapter;
  final InMemoryTokenStore store;
  final FakeServiceRequestRepository repo;
  final FakeRealtimeConnection realtime;
}

const storedTokens = AuthTokens(accessToken: 'a1', refreshToken: 'r1');

/// Pumps the real [LedCareApp] with the real router, auth controller and API
/// client; only the HTTP adapter, token storage, repository and realtime
/// transport are faked.
Future<TestApp> pumpApp(
  WidgetTester tester, {
  AuthTokens? tokens,
  Map<String, dynamic>? me,
  FakeHandler? handler,
  FakeServiceRequestRepository? repo,
}) async {
  final store = InMemoryTokenStore(tokens);
  final adapter = FakeAdapter(handler ??
      (r) {
        if (r.path == '/api/me' && me != null) return FakeResponse(200, me);
        return const FakeResponse(401, {'title': 'Unauthorized', 'status': 401});
      });
  final fakeRepo = repo ?? FakeServiceRequestRepository();
  final realtime = FakeRealtimeConnection();

  await tester.pumpWidget(ProviderScope(
    retry: noRetry,
    overrides: [
      tokenStoreProvider.overrideWithValue(store),
      apiClientProvider.overrideWith((ref) => ApiClient(
            baseUrl: 'http://api.test',
            tokenStore: store,
            onSessionExpired: () =>
                ref.read(authControllerProvider.notifier).sessionExpired(),
            adapter: adapter,
          )),
      realtimeConnectionProvider.overrideWithValue(realtime),
      serviceRequestRepositoryProvider
          .overrideWithValue(fakeRepo as ServiceRequestRepository),
    ],
    child: const LedCareApp(),
  ));
  await settle(tester);
  final container = ProviderScope.containerOf(tester.element(find.byType(LedCareApp)));
  return TestApp(container, adapter, store, fakeRepo, realtime);
}

/// Lets futures, the realtime debounce timer and animations finish.
Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}
