import 'package:dio/dio.dart';
import 'package:spotify_clone/core/token_storage.dart';

class TokenPair {
  const TokenPair({required this.accessToken, required this.refreshToken});

  factory TokenPair.fromJson(Map<String, dynamic> json) => TokenPair(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );

  final String accessToken;
  final String refreshToken;
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    required this._dio,
    required this._storage,
    required String baseUrl,
  }) {
    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.add(_AuthInterceptor(this));
  }

  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';

  final Dio _dio;
  final TokenStorage _storage;

  static const _authRetriedKey = '_authRetried';
  static const _refreshPath = '/auth/refresh';

  Future<Response<dynamic>> get(String path) => _dio.get<dynamic>(path);

  Future<Response<dynamic>> post(String path, {Object? data}) =>
      _dio.post<dynamic>(path, data: data);

  Future<void> clearTokens() async {
    await _storage.delete(accessTokenKey);
    await _storage.delete(refreshTokenKey);
  }

  Future<TokenPair?> _refreshTokens() async {
    final refreshToken = await _storage.read(refreshTokenKey);
    if (refreshToken == null) {
      return null;
    }
    try {
      final response = await _dio.post<dynamic>(
        _refreshPath,
        data: {'refreshToken': refreshToken},
      );
      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
      final pair = TokenPair.fromJson(response.data as Map<String, dynamic>);
      await _storage.write(accessTokenKey, pair.accessToken);
      await _storage.write(refreshTokenKey, pair.refreshToken);
      return pair;
    } on DioException {
      await clearTokens();
      return null;
    }
  }

  Future<void> _sendRaw(
    RequestOptions options,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._api);

  final ApiClient _api;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _api._storage.read(ApiClient.accessTokenKey).then((token) {
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    }, onError: (Object _) {
      handler.next(options);
    });
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    final alreadyRetried = options.extra[ApiClient._authRetriedKey] == true;
    final isRefreshCall = options.path.contains(ApiClient._refreshPath);

    if (isUnauthorized && !alreadyRetried && !isRefreshCall) {
      options.extra[ApiClient._authRetriedKey] = true;
      final pair = await _api._refreshTokens();
      if (pair != null) {
        options.headers['Authorization'] = 'Bearer ${pair.accessToken}';
        await _api._sendRaw(options, handler);
        return;
      }
      await _api.clearTokens();
    }
    handler.next(err);
  }
}