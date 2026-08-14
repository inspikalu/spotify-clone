import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

typedef AudioQueueEntry = ({
  Uri uri,
  String title,
  String artist,
  String? album,
  Uri? artUri,
});

abstract class AudioEngine {
  Future<void> setQueue(List<AudioQueueEntry> queue);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> skipToIndex(int index);
  Future<void> setLoopMode(LoopMode mode);
  Future<void> dispose();

  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<PlayerState> get playerStateStream;
  Stream<int?> get currentIndexStream;
}

class JustAudioEngine implements AudioEngine {
  JustAudioEngine({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> setQueue(List<AudioQueueEntry> queue) async {
    await _player.setAudioSources([
      for (final entry in queue)
        AudioSource.uri(
          entry.uri,
          tag: MediaItem(
            id: entry.uri.toString(),
            title: entry.title,
            artist: entry.artist,
            album: entry.album,
            artUri: entry.artUri,
          ),
        ),
    ]);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToIndex(int index) => _player.seek(Duration.zero, index: index);

  @override
  Future<void> setLoopMode(LoopMode mode) => _player.setLoopMode(mode);

  @override
  Future<void> dispose() => _player.dispose();

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  @override
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
}