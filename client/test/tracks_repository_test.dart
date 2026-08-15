import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotify_clone/core/api_client.dart';
import 'package:spotify_clone/core/token_storage.dart';
import 'package:spotify_clone/features/tracks/tracks_repository.dart';

class _FakeAdapter implements HttpClientAdapter {
  Future<ResponseBody> Function(RequestOptions options) handler =
      (options) async => ResponseBody.fromString('[]', 200, headers: {'content-type': ['application/json']});

  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    lastOptions = options;
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late _FakeAdapter adapter;
  late TracksRepository repository;

  setUp(() {
    dio = Dio();
    adapter = _FakeAdapter();
    dio.httpClientAdapter = adapter;
    final api = ApiClient(
      dio: dio,
      storage: MemoryTokenStorage(),
      baseUrl: 'http://test.local',
    );
    repository = TracksRepository(api);
  });

  group('fetchTracks', () {
    test('returns the list of tracks parsed from GET /tracks', () async {
      adapter.handler = (options) async => ResponseBody.fromString('''
        [
          {
            "id": "1",
            "title": "First Track",
            "artist": "Artist One",
            "album": "Album",
            "durationMs": 125000,
            "coverUrl": "http://test.local/covers/1.jpg",
            "audioUrl": "http://test.local/audio/1.mp3",
            "createdAt": "2026-08-14T10:00:00Z"
          }
        ]
      ''', 200, headers: {'content-type': ['application/json']});

      final tracks = await repository.fetchTracks();

      expect(adapter.lastOptions?.path, '/tracks');
      expect(tracks, hasLength(1));
      final track = tracks.single;
      expect(track.id, '1');
      expect(track.title, 'First Track');
      expect(track.artist, 'Artist One');
      expect(track.album, 'Album');
      expect(track.durationLabel, '2:05');
      expect(track.coverUrl, 'http://test.local/covers/1.jpg');
      expect(track.audioUrl, 'http://test.local/audio/1.mp3');
    });

    test('propagates an error when the response is not a list', () async {
      adapter.handler = (options) async => ResponseBody.fromString(
        '{"error": "boom"}',
        500,
        headers: {'content-type': ['application/json']},
      );

      expect(repository.fetchTracks(), throwsA(anything));
    });
  });
}