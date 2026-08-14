import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:spotify_clone/features/player/audio_engine.dart';
import 'package:spotify_clone/features/player/playback_controller.dart';
import 'package:spotify_clone/features/player/player_providers.dart';
import 'package:spotify_clone/features/tracks/track.dart';

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

Track _track(String id) => Track(
      id: id,
      title: 'Track $id',
      artist: 'Artist $id',
      durationMs: 1000 * (int.parse(id) + 1) * 60,
      audioUrl: 'http://test.local/audio/$id.mp3',
      createdAt: DateTime(2026, 8, 14),
    );

void main() {
  late FakeAudioEngine engine;
  late ProviderContainer container;
  late PlaybackController controller;

  setUp(() {
    engine = FakeAudioEngine();
    container = ProviderContainer(
      overrides: [
        audioEngineProvider.overrideWithValue(engine),
        randomProvider.overrideWithValue(Random(42)),
      ],
    );
    addTearDown(container.dispose);
    controller = container.read(playbackControllerProvider.notifier);
  });

  test('playTrack sets the queue, current track and calls play', () async {
    final trackA = _track('1');
    final trackB = _track('2');

    await controller.playTrack(trackA, [trackA, trackB]);

    final state = container.read(playbackControllerProvider);
    expect(state.queue, [trackA, trackB]);
    expect(state.currentTrack, trackA);
    expect(engine.queue, hasLength(2));
    expect(engine.queue!.first.uri.toString(), trackA.audioUrl);
    expect(engine.queue!.first.title, 'Track 1');
    expect(engine.skippedIndexes, [0]);
    expect(engine.playCalls, 1);
  });

  test('next advances through the queue and wraps at the end', () async {
    final trackA = _track('1');
    final trackB = _track('2');
    final trackC = _track('3');
    await controller.playTrack(trackB, [trackA, trackB, trackC]);

    engine.playingAt(1);
    await pumpEventQueue();
    await controller.next();
    expect(engine.skippedIndexes.last, 2);

    engine.playingAt(2);
    await pumpEventQueue();
    await controller.next();
    expect(engine.skippedIndexes.last, 0);
  });

  test('previous goes back and wraps at the start', () async {
    final trackA = _track('1');
    final trackB = _track('2');
    await controller.playTrack(trackB, [trackA, trackB]);

    engine.playingAt(1);
    await pumpEventQueue();
    await controller.previous();
    expect(engine.skippedIndexes.last, 0);

    engine.playingAt(0);
    await pumpEventQueue();
    await controller.previous();
    expect(engine.skippedIndexes.last, 1);
  });

  test('toggleShuffle reorders the play order but keeps membership',
      () async {
    final tracks = [_track('1'), _track('2'), _track('3')];
    await controller.playTrack(tracks.first, tracks);

    await controller.toggleShuffle();

    final state = container.read(playbackControllerProvider);
    expect(state.shuffleEnabled, isTrue);
    expect(
      state.playOrder..sort(),
      orderedEquals([0, 1, 2]),
    );

    await controller.toggleShuffle();
    expect(
      container.read(playbackControllerProvider).playOrder,
      orderedEquals([0, 1, 2]),
    );
    expect(container.read(playbackControllerProvider).shuffleEnabled, isFalse);
  });

  test('cycleRepeat cycles off → one → all → off and sets engine loop mode',
      () async {
    await controller.cycleRepeat();
    expect(container.read(playbackControllerProvider).repeatMode, RepeatMode.one);

    await controller.cycleRepeat();
    expect(container.read(playbackControllerProvider).repeatMode, RepeatMode.all);

    await controller.cycleRepeat();
    expect(container.read(playbackControllerProvider).repeatMode, RepeatMode.off);

    expect(engine.loopModes, [LoopMode.one, LoopMode.all, LoopMode.off]);
  });

  test('seek delegates to the engine', () async {
    await controller.seek(const Duration(seconds: 15));
    expect(engine.lastSeek, const Duration(seconds: 15));
  });
}