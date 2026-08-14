import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:spotify_clone/features/player/audio_engine.dart';
import 'package:spotify_clone/features/tracks/track.dart';

Track testTrack(
  String id, {
  int? durationMs,
  String? album,
  String? coverUrl,
}) =>
    Track(
      id: id,
      title: 'Track $id',
      artist: 'Artist $id',
      album: album,
      durationMs: durationMs ?? 1000 * (int.parse(id) + 1) * 60,
      coverUrl: coverUrl,
      audioUrl: 'http://test.local/audio/$id.mp3',
      createdAt: DateTime(2026, 8, 14),
    );

class FakeAudioEngine implements AudioEngine {
  final positionController = StreamController<Duration>();
  final durationController = StreamController<Duration?>();
  final playerStateController = StreamController<PlayerState>();
  final currentIndexController = StreamController<int?>();

  List<AudioQueueEntry>? queue;
  int playCalls = 0;
  int pauseCalls = 0;
  Duration? lastSeek;
  final List<int> skippedIndexes = [];
  final List<LoopMode> loopModes = [];

  @override
  Future<void> setQueue(List<AudioQueueEntry> queue) async {
    this.queue = queue;
  }

  @override
  Future<void> play() async => playCalls++;

  @override
  Future<void> pause() async => pauseCalls++;

  @override
  Future<void> seek(Duration position) async => lastSeek = position;

  @override
  Future<void> skipToIndex(int index) async => skippedIndexes.add(index);

  @override
  Future<void> setLoopMode(LoopMode mode) async => loopModes.add(mode);

  @override
  Future<void> dispose() async {
    for (final controller in [
      positionController,
      durationController,
      playerStateController,
      currentIndexController,
    ]) {
      await controller.close();
    }
  }

  @override
  Stream<Duration> get positionStream => positionController.stream;

  @override
  Stream<Duration?> get durationStream => durationController.stream;

  @override
  Stream<PlayerState> get playerStateStream => playerStateController.stream;

  @override
  Stream<int?> get currentIndexStream => currentIndexController.stream;

  void playingAt(int index) {
    currentIndexController.add(index);
    playerStateController.add(PlayerState(true, ProcessingState.ready));
  }
}