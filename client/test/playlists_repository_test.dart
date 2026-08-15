import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotify_clone/core/api_client.dart';
import 'package:spotify_clone/core/token_storage.dart';
import 'package:spotify_clone/features/playlists/playlists_repository.dart';

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
  late PlaylistsRepository repository;

  setUp(() {
    dio = Dio();
    adapter = _FakeAdapter();
    dio.httpClientAdapter = adapter;
    final api = ApiClient(
      dio: dio,
      storage: MemoryTokenStorage(),
      baseUrl: 'http://test.local',
    );
    repository = PlaylistsRepository(api);
  });

  group('PlaylistsRepository', () {
    test('fetchUserPlaylists parses list of playlists', () async {
      adapter.handler = (options) async => ResponseBody.fromString('''
        [
          {
            "id": "p1",
            "name": "Afrobeats 2026",
            "ownerId": "u1",
            "trackCount": 5,
            "coverUrls": ["http://test.local/c1.jpg"],
            "createdAt": "2026-08-15T08:00:00Z"
          }
        ]
      ''', 200, headers: {'content-type': ['application/json']});

      final list = await repository.fetchUserPlaylists();
      expect(adapter.lastOptions?.path, '/playlists');
      expect(list, hasLength(1));
      expect(list.first.name, 'Afrobeats 2026');
      expect(list.first.trackCount, 5);
    });

    test('createPlaylist sends POST /playlists and parses result', () async {
      adapter.handler = (options) async => ResponseBody.fromString('''
        {
          "id": "p2",
          "name": "Workout Mix",
          "ownerId": "u1",
          "trackCount": 0,
          "coverUrls": [],
          "createdAt": "2026-08-15T08:00:00Z"
        }
      ''', 201, headers: {'content-type': ['application/json']});

      final playlist = await repository.createPlaylist('Workout Mix');
      expect(adapter.lastOptions?.path, '/playlists');
      expect(adapter.lastOptions?.method, 'POST');
      expect(playlist.id, 'p2');
      expect(playlist.name, 'Workout Mix');
    });

    test('addTrackToPlaylist sends trackId in POST body', () async {
      adapter.handler = (options) async => ResponseBody.fromString('{"success": true}', 200);

      await repository.addTrackToPlaylist('p1', 't100');
      expect(adapter.lastOptions?.path, '/playlists/p1/tracks');
      expect(adapter.lastOptions?.method, 'POST');
      expect(adapter.lastOptions?.data, {'trackId': 't100'});
    });

    test('likeTrack sends POST /tracks/:id/like', () async {
      adapter.handler = (options) async => ResponseBody.fromString('{"success": true}', 200);

      await repository.likeTrack('t1');
      expect(adapter.lastOptions?.path, '/tracks/t1/like');
      expect(adapter.lastOptions?.method, 'POST');
    });

    test('fetchLikedTracks parses tracks', () async {
      adapter.handler = (options) async => ResponseBody.fromString('''
        [
          {
            "id": "t1",
            "title": "TEA",
            "artist": "Rema",
            "durationMs": 180000,
            "audioUrl": "http://test.local/audio/1.mp3",
            "createdAt": "2026-08-15T08:00:00Z"
          }
        ]
      ''', 200, headers: {'content-type': ['application/json']});

      final tracks = await repository.fetchLikedTracks();
      expect(adapter.lastOptions?.path, '/me/liked-tracks');
      expect(tracks, hasLength(1));
      expect(tracks.first.title, 'TEA');
    });
  });
}
