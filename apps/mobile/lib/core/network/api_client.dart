import 'dart:async';

import 'package:dio/dio.dart';

import '../auth/token_storage.dart';

/// `RequestOptions.extra` flag: do not attach a bearer token or try to refresh
/// (login / refresh endpoints).
const kSkipAuth = 'ledcare.skipAuth';
const _kAuthRetried = 'ledcare.authRetried';

/// Builds the authenticated [Dio] used by every repository.
///
/// * attaches `Authorization: Bearer <access>` from the [TokenStore];
/// * on `401` refreshes once via `POST /api/auth/refresh` â€” concurrent 401s
///   share a single in-flight refresh â€” then retries the request once;
/// * when the refresh token is rejected, clears the store and calls
///   [onSessionExpired] (the auth controller routes to the login screen).
class ApiClient {
  ApiClient._(this.dio, this._auth, this._tokenStore);

  factory ApiClient({
    required String baseUrl,
    required TokenStore tokenStore,
    required FutureOr<void> Function() onSessionExpired,
    HttpClientAdapter? adapter,
  }) {
    final dio = createApiDio(
      baseUrl: baseUrl,
      tokenStore: tokenStore,
      onSessionExpired: onSessionExpired,
      adapter: adapter,
    );
    final auth = dio.interceptors.whereType<AuthInterceptor>().single;
    return ApiClient._(dio, auth, tokenStore);
  }

  final Dio dio;
  final AuthInterceptor _auth;
  final TokenStore _tokenStore;

  /// Access token for non-Dio transports (SignalR `access_token`). Refreshes
  /// first (single-flight, shared with Dio) when it is about to expire.
  Future<String?> freshAccessToken() async {
    final tokens = await _tokenStore.read();
    if (tokens == null) return null;
    if (!tokens.expiresWithin(const Duration(seconds: 60))) {
      return tokens.accessToken;
    }
    return (await _auth.refreshTokens())?.accessToken;
  }
}

Dio createApiDio({
  required String baseUrl,
  required TokenStore tokenStore,
  required FutureOr<void> Function() onSessionExpired,
  HttpClientAdapter? adapter,
}) {
  BaseOptions options() => BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
        headers: {'Accept': 'application/json'},
      );

  final refreshDio = Dio(options());
  final dio = Dio(options());
  if (adapter != null) {
    refreshDio.httpClientAdapter = adapter;
    dio.httpClientAdapter = adapter;
  }
  dio.interceptors.add(AuthInterceptor(
    tokenStore: tokenStore,
    refreshDio: refreshDio,
    retryDio: dio,
    onSessionExpired: onSessionExpired,
  ));
  return dio;
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.tokenStore,
    required this.refreshDio,
    required this.retryDio,
    required this.onSessionExpired,
  });

  final TokenStore tokenStore;
  final Dio refreshDio;
  final Dio retryDio;
  final FutureOr<void> Function() onSessionExpired;

  Future<AuthTokens?>? _inFlightRefresh;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[kSkipAuth] != true) {
      final tokens = await tokenStore.read();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        request.extra[kSkipAuth] == true ||
        request.extra[_kAuthRetried] == true) {
      return handler.next(err);
    }

    var tokens = await tokenStore.read();
    if (tokens == null) {
      await _expire();
      return handler.next(err);
    }

    // If another request already rotated the token after this one was sent,
    // just retry with the new token instead of refreshing again.
    final sentAuth = request.headers['Authorization'];
    if (sentAuth == null || sentAuth == 'Bearer ${tokens.accessToken}') {
      tokens = await refreshTokens();
    }
    if (tokens == null) return handler.next(err);

    try {
      final retry = request.copyWith(
        headers: {
          ...request.headers,
          'Authorization': 'Bearer ${tokens.accessToken}',
        },
        extra: {...request.extra, _kAuthRetried: true},
      );
      handler.resolve(await retryDio.fetch<dynamic>(retry));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Single-flight refresh: concurrent callers await the same future.
  Future<AuthTokens?> refreshTokens() =>
      _inFlightRefresh ??= _refresh().whenComplete(() => _inFlightRefresh = null);

  Future<AuthTokens?> _refresh() async {
    final current = await tokenStore.read();
    if (current == null) {
      await _expire();
      return null;
    }
    try {
      final response = await refreshDio.post<Map<String, dynamic>>(
        '/api/auth/refresh',
        data: {'refreshToken': current.refreshToken},
        options: Options(extra: {kSkipAuth: true}),
      );
      final tokens = AuthTokens.fromResponse(response.data!);
      await tokenStore.write(tokens);
      return tokens;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // Rejected refresh token â†’ session is over. Transport errors keep the
      // session so the user is not logged out by a flaky network.
      if (status != null && status >= 400 && status < 500) {
        await _expire();
      }
      return null;
    }
  }

  Future<void> _expire() async {
    await tokenStore.clear();
    await onSessionExpired();
  }
}
