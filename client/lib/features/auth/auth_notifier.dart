import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/features/auth/auth_providers.dart';
import 'package:spotify_clone/features/auth/auth_repository.dart';

sealed class AuthState {
  const AuthState();
}

class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.email});

  final String email;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    restore();
    return const AuthUnknown();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> restore() async {
    final email = await _repository.restoreSession();
    state = email == null
        ? const AuthUnauthenticated()
        : AuthAuthenticated(email: email);
  }

  Future<void> logIn({
    required String email,
    required String password,
  }) async {
    await _repository.logIn(email: email, password: password);
    state = AuthAuthenticated(email: email);
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    await _repository.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );
    state = AuthAuthenticated(email: email);
  }

  Future<void> logOut() async {
    await _repository.logOut();
    state = const AuthUnauthenticated();
  }
}