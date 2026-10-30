import 'package:dio/dio.dart';

import '../network/api_client.dart';
import '../network/api_exception.dart';
import 'auth_models.dart';
import 'token_storage.dart';

class AuthRepository {
  AuthRepository(this._dio, this._tokens);

  final Dio _dio;
  final TokenStore _tokens;

  /// Bearer login (no `useCookies`). Stores the token pair on success.
  Future<void> login(String email, String password) => guardApi(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/api/auth/login',
          data: {'email': email, 'password': password},
          options: Options(extra: {kSkipAuth: true}),
        );
        // Validate the shape against the contract DTO before persisting.
        AccessTokenResponse.fromJson(response.data!);
        await _tokens.write(AuthTokens.fromResponse(response.data!));
      });

  Future<MeResponse> me() => guardApi(() async {
        final response = await _dio.get<Map<String, dynamic>>('/api/me');
        return MeResponse.fromJson(response.data!);
      });

  Future<bool> hasStoredSession() async => (await _tokens.read()) != null;

  /// Bearer sessions are stateless on the server; signing out on this device
  /// means discarding the tokens. (`/api/auth/logout` only clears the web cookie.)
  Future<void> clearSession() => _tokens.clear();
}
