import 'dart:io';
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

  group('uploadTrack', () {
    test('sends title, artist and file as multipart to POST /tracks',
        () async {
      final dir = Directory.systemTemp.createTempSync();
      addTearDown(() => dir.deleteSync(recursive: true));
      final audio = File('${dir.path}/demo.mp3')..writeAsStringSync('audio');

      await repository.uploadTrack(
        title: 'Demo',
        artist: 'Artist',
        audioPath: audio.path,
        audioName: 'demo.mp3',
      );

      expect(adapter.lastOptions?.path, '/tracks');
      expect(adapter.lastOptions?.method, 'POST');
      final formData = adapter.lastOptions?.data as FormData;
      expect(formData.fields.map((f) => f.key),
          containsAllInOrder(['title', 'artist']));
      expect(
        formData.fields.singleWhere((f) => f.key == 'title').value,
        'Demo',
      );
      expect(
        formData.fields.singleWhere((f) => f.key == 'artist').value,
        'Artist',
      );
      final files = formData.files;
      expect(files, hasLength(1));
      expect(files.single.key, 'file');
      expect(files.single.value.filename, 'demo.mp3');
    });

    test('includes album and cover only when provided', () async {
      final dir = Directory.systemTemp.createTempSync();
      addTearDown(() => dir.deleteSync(recursive: true));
      final audio = File('${dir.path}/demo.mp3')..writeAsStringSync('audio');
      final cover = File('${dir.path}/cover.jpg')..writeAsStringSync('cover');

      await repository.uploadTrack(
        title: 'Demo',
        artist: 'Artist',
        audioPath: audio.path,
        coverPath: cover.path,
      );
      var formData = adapter.lastOptions?.data as FormData;
      expect(formData.fields.where((f) => f.key == 'album'), isEmpty);
      expect(formData.files.map((f) => f.key), contains('cover'));

      await repository.uploadTrack(
        title: 'Demo',
        artist: 'Artist',
        album: 'Album',
        audioPath: audio.path,
      );
      formData = adapter.lastOptions?.data as FormData;
      expect(
        formData.fields.any((f) => f.key == 'album' && f.value == 'Album'),
        isTrue,
      );
      expect(formData.files.map((f) => f.key), isNot(contains('cover')));
    });
  });
}