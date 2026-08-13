import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotify_clone/core/api_client.dart';
import 'package:spotify_clone/core/token_storage.dart';
import 'package:spotify_clone/features/auth/auth_notifier.dart';
import 'package:spotify_clone/features/auth/auth_providers.dart';
import 'package:spotify_clone/features/auth/auth_repository.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository()
      : super(
          ApiClient(
            dio: Dio(),
            storage: MemoryTokenStorage(),
            baseUrl: 'http://localhost:1',
          ),
          MemoryTokenStorage(),
        );

  String? restoreEmail = 'existing@test.local';
  bool failLogin = false;

  @override
  Future<String?> restoreSession() async => restoreEmail;

  @override
  Future<void> logIn({required String email, required String password}) async {
    if (failLogin) {
      throw const AuthException('bad credentials');
    }
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {}

  @override
  Future<void> logOut() async {}
}

ProviderContainer _container(_FakeAuthRepository repository) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('starts unknown, then auto-restores to authenticated from storage',
      () async {
    final container = _container(_FakeAuthRepository());

    expect(container.read(authStateProvider), isA<AuthUnknown>());

    await pumpEventQueue();

    final state = container.read(authStateProvider);
    expect(state, isA<AuthAuthenticated>());
    expect((state as AuthAuthenticated).email, 'existing@test.local');
  });

  test('no stored session restores to unauthenticated', () async {
    final repository = _FakeAuthRepository()..restoreEmail = null;
    final container = _container(repository);

    expect(container.read(authStateProvider), isA<AuthUnknown>());
    await pumpEventQueue();

    expect(container.read(authStateProvider), isA<AuthUnauthenticated>());
  });

  test('logout returns to unauthenticated', () async {
    final container = _container(_FakeAuthRepository());
    expect(container.read(authStateProvider), isA<AuthUnknown>());
    await pumpEventQueue();
    expect(container.read(authStateProvider), isA<AuthAuthenticated>());

    await container.read(authStateProvider.notifier).logOut();

    expect(container.read(authStateProvider), isA<AuthUnauthenticated>());
  });

  test('failed login stays unauthenticated and rethrows', () async {
    final repository = _FakeAuthRepository()
      ..restoreEmail = null
      ..failLogin = true;
    final container = _container(repository);
    await pumpEventQueue();

    final notifier = container.read(authStateProvider.notifier);
    await expectLater(
      notifier.logIn(email: 'a@b.c', password: 'wrong'),
      throwsA(isA<AuthException>()),
    );
    expect(container.read(authStateProvider), isA<AuthUnauthenticated>());
  });
}