import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/core/api_client.dart';
import 'package:spotify_clone/core/token_storage.dart';
import 'package:spotify_clone/features/auth/auth_notifier.dart';
import 'package:spotify_clone/features/auth/auth_repository.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://spotify-clone-n891.onrender.com',
);

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(),
);

final dioProvider = Provider<Dio>(
  (ref) => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  ),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    dio: ref.watch(dioProvider),
    storage: ref.watch(tokenStorageProvider),
    baseUrl: apiBaseUrl,
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  ),
);

final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

final resetTokenProvider = StateProvider<String?>((ref) => null);