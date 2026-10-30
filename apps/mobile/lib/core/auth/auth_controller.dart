import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import '../network/network_providers.dart';
import 'auth_models.dart';
import 'auth_repository.dart';

sealed class AuthState {
  const AuthState();
}

/// Cold start: stored session not checked yet.
class AuthRestoring extends AuthState {
  const AuthRestoring();
}

/// Tokens exist but `/api/me` could not be reached (offline / server down).
class AuthRestoreFailed extends AuthState {
  const AuthRestoreFailed(this.error);
  final ApiException error;
}

class AuthSignedOut extends AuthState {
  const AuthSignedOut({this.sessionExpired = false});
  final bool sessionExpired;
}

class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.me);
  final MeResponse me;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider).dio,
    ref.watch(tokenStoreProvider),
  );
});

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    scheduleMicrotask(restore);
    return const AuthRestoring();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  /// Restores the session on cold start by calling `GET /api/me`
  /// (the Dio interceptor refreshes an expired access token transparently).
  Future<void> restore() async {
    state = const AuthRestoring();
    if (!await _repo.hasStoredSession()) {
      state = const AuthSignedOut();
      return;
    }
    try {
      state = AuthSignedIn(await _repo.me());
    } on ApiException catch (e) {
      if (e.kind == ApiErrorKind.network || e.kind == ApiErrorKind.server) {
        state = AuthRestoreFailed(e);
      } else {
        await _repo.clearSession();
        state = const AuthSignedOut(sessionExpired: true);
      }
    }
  }

  /// Throws [ApiException] on failure (the login screen renders it).
  Future<void> login(String email, String password) async {
    await _repo.login(email.trim(), password);
    try {
      state = AuthSignedIn(await _repo.me());
    } catch (_) {
      await _repo.clearSession();
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repo.clearSession();
    state = const AuthSignedOut();
  }

  /// Called by the API client when the refresh token was rejected.
  void sessionExpired() {
    if (state is AuthSignedOut) return;
    state = const AuthSignedOut(sessionExpired: true);
  }
}
