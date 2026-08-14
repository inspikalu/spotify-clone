import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/features/player/audio_engine.dart';
import 'package:spotify_clone/features/player/playback_controller.dart';
import 'package:spotify_clone/features/tracks/track.dart';

final audioEngineProvider = Provider<AudioEngine>(
  (ref) => JustAudioEngine(),
);

final randomProvider = Provider<Random>(
  (ref) => Random(),
);

final playbackControllerProvider =
    NotifierProvider<PlaybackController, PlaybackState>(
  PlaybackController.new,
);

final currentTrackProvider = Provider<Track?>(
  (ref) => ref.watch(playbackControllerProvider).currentTrack,
);

final isPlayingProvider = Provider<bool>(
  (ref) => ref.watch(playbackControllerProvider.select((s) => s.isPlaying)),
);

final positionProvider = Provider<Duration>(
  (ref) => ref.watch(playbackControllerProvider.select((s) => s.position)),
);

final repeatModeProvider = Provider<RepeatMode>(
  (ref) => ref.watch(playbackControllerProvider.select((s) => s.repeatMode)),
);

final shuffleProvider = Provider<bool>(
  (ref) => ref.watch(playbackControllerProvider.select((s) => s.shuffleEnabled)),
);