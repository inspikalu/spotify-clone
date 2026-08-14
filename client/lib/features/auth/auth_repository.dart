import 'package:spotify_clone/core/token_storage.dart';
import 'package:spotify_clone/core/api_client.dart';

class AuthRepository {
  AuthRepository(this._api, this._storage);

  final ApiClient _api;
  final TokenStorage _storage;

  Future<String?> restoreSession() async {
    final accessToken = await _storage.read(ApiClient.accessTokenKey);
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }
    try {
      final response = await _api.get('/auth/me');
      final json = response.data as Map<String, dynamic>;
      return (json['email'] as String?) ?? json['user']?['email'] as String?;
    } on Exception {
      await _api.clearTokens();
      return null;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await _api.post('/auth/signup', data: {
      'email': email,
      'password': password,
      if (displayName != null && displayName.isNotEmpty)
        'displayName': displayName,
    });
    final json = response.data as Map<String, dynamic>;
    final tokenPair = TokenPair.fromJson({
      'accessToken': json['accessToken'] as String,
      'refreshToken': json['refreshToken'] as String,
    });
    await _storeTokens(tokenPair);
  }

  Future<void> logIn({required String email, required String password}) async {
    final response = await _api.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final json = response.data as Map<String, dynamic>;
    final tokenPair = TokenPair.fromJson({
      'accessToken': json['accessToken'] as String,
      'refreshToken': json['refreshToken'] as String,
    });
    await _storeTokens(tokenPair);
  }

  Future<void> logOut() async {
    await _api.clearTokens();
  }

  Future<String> googleSignIn(String idToken) async {
    final response = await _api.post('/auth/google', data: {'idToken': idToken});
    final json = response.data as Map<String, dynamic>;
    final tokenPair = TokenPair.fromJson({
      'accessToken': json['accessToken'] as String,
      'refreshToken': json['refreshToken'] as String,
    });
    await _storeTokens(tokenPair);
    return (json['user'] as Map<String, dynamic>)['email'] as String;
  }

  Future<void> forgotPassword(String email) async {
    await _api.post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _api.post('/auth/reset-password', data: {
      'token': token,
      'newPassword': newPassword,
    });
  }

  Future<void> _storeTokens(TokenPair pair) async {
    await _storage.write(ApiClient.accessTokenKey, pair.accessToken);
    await _storage.write(ApiClient.refreshTokenKey, pair.refreshToken);
  }
}