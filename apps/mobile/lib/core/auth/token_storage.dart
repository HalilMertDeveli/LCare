import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Access + refresh token pair returned by `POST /api/auth/login|refresh`.
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.accessExpiresAt,
  });

  /// Builds tokens from an `AccessTokenResponse` body.
  factory AuthTokens.fromResponse(Map<String, dynamic> json, {DateTime? now}) {
    final expiresIn = (json['expiresIn'] as num?)?.toInt();
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      accessExpiresAt: expiresIn == null
          ? null
          : (now ?? DateTime.now()).toUtc().add(Duration(seconds: expiresIn)),
    );
  }

  final String accessToken;
  final String refreshToken;

  /// Client-side estimate of the (opaque) access token's expiry.
  final DateTime? accessExpiresAt;

  bool expiresWithin(Duration margin, {DateTime? now}) {
    final at = accessExpiresAt;
    if (at == null) return true;
    return !(now ?? DateTime.now()).toUtc().add(margin).isBefore(at);
  }
}

/// Persistence for the bearer session. Production uses [SecureTokenStore];
/// tokens are never written to shared preferences, files or logs.
abstract class TokenStore {
  Future<AuthTokens?> read();
  Future<void> write(AuthTokens tokens);
  Future<void> clear();
}

/// Keychain (iOS) / Keystore-backed storage (Android).
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  static const _accessKey = 'ledcare.accessToken';
  static const _refreshKey = 'ledcare.refreshToken';
  static const _expiresKey = 'ledcare.accessExpiresAt';

  final FlutterSecureStorage _storage;

  // Reads happen before every request; keep a decrypted copy in memory.
  AuthTokens? _cache;
  bool _loaded = false;

  @override
  Future<AuthTokens?> read() async {
    if (_loaded) return _cache;
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    final expires = await _storage.read(key: _expiresKey);
    _loaded = true;
    if (access == null || refresh == null || access.isEmpty || refresh.isEmpty) {
      return _cache = null;
    }
    return _cache = AuthTokens(
      accessToken: access,
      refreshToken: refresh,
      accessExpiresAt: expires == null ? null : DateTime.tryParse(expires),
    );
  }

  @override
  Future<void> write(AuthTokens tokens) async {
    _cache = tokens;
    _loaded = true;
    await _storage.write(key: _accessKey, value: tokens.accessToken);
    await _storage.write(key: _refreshKey, value: tokens.refreshToken);
    await _storage.write(
      key: _expiresKey,
      value: tokens.accessExpiresAt?.toIso8601String(),
    );
  }

  @override
  Future<void> clear() async {
    _cache = null;
    _loaded = true;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _expiresKey);
  }
}

/// Non-persistent store (tests).
class InMemoryTokenStore implements TokenStore {
  InMemoryTokenStore([this._tokens]);

  AuthTokens? _tokens;

  AuthTokens? get current => _tokens;

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> write(AuthTokens tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}
