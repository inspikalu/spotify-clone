import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:spotify_clone/features/player/audio_engine.dart';
import 'package:spotify_clone/features/player/player_providers.dart';
import 'package:spotify_clone/features/tracks/track.dart';

enum RepeatMode { off, one, all }

class PlaybackState {
  const PlaybackState({
    this.queue = const [],
    this.playOrder = const [],
    this.currentIndex = -1,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration,
    this.shuffleEnabled = false,
    this.repeatMode = RepeatMode.off,
    this.loading = false,
  });

  final List<Track> queue;
  final List<int> playOrder;
  final int currentIndex;
  final bool isPlaying;
  final Duration position;
  final Duration? duration;
  final bool shuffleEnabled;
  final RepeatMode repeatMode;
  final bool loading;

  Track? get currentTrack =>
      currentIndex < 0 || currentIndex >= queue.length
          ? null
          : queue[currentIndex];

  PlaybackState copyWith({
    List<Track>? queue,
    List<int>? playOrder,
    int? currentIndex,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    bool? shuffleEnabled,
    RepeatMode? repeatMode,
    bool? loading,
  }) =>
      PlaybackState(
        queue: queue ?? this.queue,
        playOrder: playOrder ?? this.playOrder,
        currentIndex: currentIndex ?? this.currentIndex,
        isPlaying: isPlaying ?? this.isPlaying,
        position: position ?? this.position,
        duration: duration ?? this.duration,
        shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
        repeatMode: repeatMode ?? this.repeatMode,
        loading: loading ?? this.loading,
      );
}

class PlaybackController extends Notifier<PlaybackState> {
  late final AudioEngine _engine;
  late final Random _random;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  @override
  PlaybackState build() {
    _engine = ref.watch(audioEngineProvider);
    _random = ref.watch(randomProvider);
    _subscriptions.addAll([
      _engine.positionStream.listen(
        (position) => state = state.copyWith(position: position),
      ),
      _engine.durationStream.listen(
        (duration) => state = state.copyWith(duration: duration),
      ),
      _engine.currentIndexStream.listen(
        (index) => state = state.copyWith(currentIndex: index ?? -1),
      ),
      _engine.playerStateStream.listen((playerState) {
        state = state.copyWith(
          isPlaying: playerState.playing,
          loading: playerState.processingState != ProcessingState.ready,
        );
      }),
    ]);
    ref.onDispose(() {
      for (final subscription in _subscriptions) {
        subscription.cancel();
      }
      _engine.dispose();
    });
    return const PlaybackState();
  }

  Future<void> playTrack(Track track, List<Track> queue) async {
    final playableQueue = queue.where((t) => t.audioUrl != null).toList();
    if (playableQueue.isEmpty) return;
    final playableIndex = playableQueue.indexOf(track).clamp(0, playableQueue.length - 1);
    state = PlaybackState(
      queue: playableQueue,
      playOrder: List<int>.generate(playableQueue.length, (i) => i),
      currentIndex: playableIndex,
      shuffleEnabled: false,
      repeatMode: state.repeatMode,
      loading: true,
    );
    await _engine.setQueue([
      for (final item in playableQueue)
        (
          uri: Uri.parse(item.audioUrl!),
          title: item.title,
          artist: item.artist,
          album: item.album,
          artUri: item.coverUrl == null ? null : Uri.parse(item.coverUrl!),
        ),
    ]);
    await _engine.skipToIndex(playableIndex);
    await _engine.play();
  }

  Future<void> togglePlayPause() async {
    if (state.queue.isEmpty) {
      return;
    }
    if (state.isPlaying) {
      await _engine.pause();
    } else {
      await _engine.play();
    }
  }

  Future<void> next() async {
    if (state.queue.isEmpty || state.currentIndex < 0) {
      return;
    }
    await _skipRelative(1);
  }

  Future<void> previous() async {
    if (state.queue.isEmpty || state.currentIndex < 0) {
      return;
    }
    await _skipRelative(-1);
  }

  Future<void> _skipRelative(int delta) async {
    final count = state.queue.length;
    final currentOrderPosition = state.playOrder.indexOf(state.currentIndex);
    final targetOrderPosition =
        (currentOrderPosition + delta + count) % count;
    final targetSourceIndex = state.playOrder[targetOrderPosition];
    await _engine.skipToIndex(targetSourceIndex);
    await _engine.play();
  }

  Future<void> seek(Duration position) => _engine.seek(position);

  Future<void> toggleShuffle() async {
    if (state.queue.isEmpty) {
      return;
    }
    final enabled = !state.shuffleEnabled;
    final playOrder = List<int>.generate(state.queue.length, (i) => i);
    if (enabled) {
      playOrder.shuffle(_random);
    }
    state = state.copyWith(shuffleEnabled: enabled, playOrder: playOrder);
  }

  Future<void> cycleRepeat() async {
    final nextMode = switch (state.repeatMode) {
      RepeatMode.off => RepeatMode.one,
      RepeatMode.one => RepeatMode.all,
      RepeatMode.all => RepeatMode.off,
    };
    state = state.copyWith(repeatMode: nextMode);
    await _engine.setLoopMode(switch (nextMode) {
      RepeatMode.off => LoopMode.off,
      RepeatMode.one => LoopMode.one,
      RepeatMode.all => LoopMode.all,
    });
  }
}