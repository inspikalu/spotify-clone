import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotify_clone/core/api_client.dart';
import 'package:spotify_clone/core/token_storage.dart';

class _FakeAdapter implements HttpClientAdapter {
  Future<ResponseBody> Function(RequestOptions options) handler =
      (options) async => ResponseBody.fromString('{}', 200);

  int calls = 0;
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    calls++;
    lastOptions = options;
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late _FakeAdapter adapter;
  late MemoryTokenStorage storage;
  late ApiClient api;

  setUp(() {
    storage = MemoryTokenStorage();
    dio = Dio();
    adapter = _FakeAdapter();
    dio.httpClientAdapter = adapter;
    api = ApiClient(dio: dio, storage: storage, baseUrl: 'http://test.local');
  });

  test('attaches the stored access token to every request', () async {
    await storage.write(ApiClient.accessTokenKey, 'token-1');

    await api.get('/auth/me');

    expect(adapter.lastOptions?.headers['Authorization'], 'Bearer token-1');
  });

  test('401 triggers one refresh, then retries with the new token', () async {
    await storage.write(ApiClient.accessTokenKey, 'access-old');
    await storage.write(ApiClient.refreshTokenKey, 'refresh-old');

    var meCalls = 0;
    adapter.handler = (options) async {
      if (options.path == '/auth/me') {
        meCalls++;
        if (meCalls == 1) {
          return ResponseBody.fromString(
            '{"message":"Unauthorized"}',
            401,
            headers: {'content-type': ['application/json']},
          );
        }
        return ResponseBody.fromString(
          '{"email":"a@b.c"}',
          200,
          headers: {'content-type': ['application/json']},
        );
      }
      if (options.path == '/auth/refresh') {
        return ResponseBody.fromString(
          '{"accessToken":"access-new","refreshToken":"refresh-new"}',
          200,
          headers: {'content-type': ['application/json']},
        );
      }
      return ResponseBody.fromString('{}', 404);
    };

    final response = await api.get('/auth/me');

    expect(response.statusCode, 200);
    expect(adapter.calls, 3);
    expect(await storage.read(ApiClient.accessTokenKey), 'access-new');
    expect(await storage.read(ApiClient.refreshTokenKey), 'refresh-new');
  });

  test('failed refresh clears tokens and propagates the error', () async {
    await storage.write(ApiClient.accessTokenKey, 'access-old');
    await storage.write(ApiClient.refreshTokenKey, 'refresh-old');

    adapter.handler = (options) async {
      return ResponseBody.fromString(
        '{"message":"Unauthorized"}',
        401,
        headers: {'content-type': ['application/json']},
      );
    };

    await expectLater(api.get('/auth/me'), throwsA(isA<DioException>()));

    expect(await storage.read(ApiClient.accessTokenKey), isNull);
    expect(await storage.read(ApiClient.refreshTokenKey), isNull);
  });
}