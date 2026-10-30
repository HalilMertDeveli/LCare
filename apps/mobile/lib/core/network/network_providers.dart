import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/token_storage.dart';
import '../config/app_config.dart';
import 'api_client.dart';

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.fromEnvironment());

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  return ApiClient(
    baseUrl: config.apiBaseUrl,
    tokenStore: ref.watch(tokenStoreProvider),
    // Read lazily: the auth controller itself depends on this client.
    onSessionExpired: () =>
        ref.read(authControllerProvider.notifier).sessionExpired(),
  );
});
