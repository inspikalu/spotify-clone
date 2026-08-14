import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotify_clone/core/api_client.dart';
import 'package:spotify_clone/core/token_storage.dart';
import 'package:spotify_clone/features/tracks/tracks_providers.dart';
import 'package:spotify_clone/features/tracks/tracks_repository.dart';
import 'package:spotify_clone/features/tracks/upload_track_screen.dart';

final class _TestPlatformFile extends PlatformFile {
  _TestPlatformFile(this._path);

  final String _path;

  @override
  String get name => _path.split(Platform.pathSeparator).last;

  @override
  Uri get uri => Uri.file(_path);

  @override
  XFile get xFile => XFile(_path);

  @override
  Future<int> length() => xFile.length();

  @override
  Future<Uint8List> readAsBytes() => xFile.readAsBytes();

  @override
  Stream<Uint8List> readAsByteStream() => xFile.openRead();
}

class _FakePicker extends FilePickerPlatform {
  PlatformFile? file;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async =>
      file;
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
    picker.file = _TestPlatformFile(audio.path);
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
    picker.file = _TestPlatformFile(audio.path);
    await tester.tap(find.text('Pick audio file'));
    await tester.pump();

    picker.file = _TestPlatformFile(cover.path);
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