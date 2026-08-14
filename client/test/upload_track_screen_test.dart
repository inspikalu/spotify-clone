import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
// ignore: implementation_imports — FilePickerPlatform is the only test seam in file_picker 11.x
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotify_clone/core/api_client.dart';
import 'package:spotify_clone/core/token_storage.dart';
import 'package:spotify_clone/features/tracks/tracks_providers.dart';
import 'package:spotify_clone/features/tracks/tracks_repository.dart';
import 'package:spotify_clone/features/tracks/upload_track_screen.dart';

class _FakePicker extends FilePickerPlatform {
  FilePickerResult? result;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    bool cancelUploadOnWindowBlur = true,
  }) async =>
      result;
}

class _FakeTracksRepository extends TracksRepository {
  _FakeTracksRepository()
      : super(
          ApiClient(
            dio: Dio(),
            storage: MemoryTokenStorage(),
            baseUrl: 'http://localhost:1',
          ),
        );

  final List<({String title, String artist, String? album, String? audioPath,
      String? coverPath})> uploads = [];
  bool failUpload = false;

  @override
  Future<void> uploadTrack({
    required String title,
    required String artist,
    String? album,
    required String audioPath,
    String? audioName,
    String? coverPath,
    void Function(int, int)? onProgress,
  }) async {
    if (failUpload) {
      throw Exception('boom');
    }
    uploads.add((
      title: title,
      artist: artist,
      album: album,
      audioPath: audioPath,
      coverPath: coverPath,
    ));
  }
}

void main() {
  late _FakePicker picker;
  late _FakeTracksRepository repository;
  late Directory tempDir;

  setUp(() {
    picker = _FakePicker();
    FilePickerPlatform.instance = picker;
    repository = _FakeTracksRepository();
    tempDir = Directory.systemTemp.createTempSync();
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  Widget harness() => ProviderScope(
        overrides: [
          tracksRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => const UploadTrackScreen(),
                    ),
                  ),
                  child: const Text('open-upload'),
                ),
              ),
            ),
          ),
        ),
      );

  testWidgets('validates that an audio file and a title are picked',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.text('open-upload'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Upload'));
    await tester.pump();
    expect(find.text('Pick an audio file first'), findsOneWidget);

    final audio = File('${tempDir.path}/demo.mp3')..writeAsStringSync('audio');
    picker.result = FilePickerResult([
      PlatformFile(name: 'demo.mp3', size: 5, path: audio.path),
    ]);
    await tester.tap(find.text('Pick audio file'));
    await tester.pump();

    await tester.tap(find.text('Upload'));
    await tester.pump();
    expect(find.text('Enter a title'), findsOneWidget);
  });

  testWidgets('uploads the picked file and pops back on success',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.text('open-upload'));
    await tester.pumpAndSettle();

    final audio = File('${tempDir.path}/demo.mp3')..writeAsStringSync('audio');
    final cover = File('${tempDir.path}/cover.jpg')..writeAsStringSync('cover');
    picker.result = FilePickerResult([
      PlatformFile(name: 'demo.mp3', size: 5, path: audio.path),
    ]);
    await tester.tap(find.text('Pick audio file'));
    await tester.pump();

    picker.result = FilePickerResult([
      PlatformFile(name: 'cover.jpg', size: 5, path: cover.path),
    ]);
    await tester.tap(find.text('Pick cover image (optional)'));
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'Demo');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Artist'), 'Artist');

    await tester.tap(find.text('Upload'));
    await tester.pumpAndSettle();

    expect(repository.uploads, hasLength(1));
    final upload = repository.uploads.single;
    expect(upload.title, 'Demo');
    expect(upload.artist, 'Artist');
    expect(upload.audioPath, audio.path);
    expect(upload.coverPath, cover.path);
    expect(find.text('open-upload'), findsOneWidget);
  });
}