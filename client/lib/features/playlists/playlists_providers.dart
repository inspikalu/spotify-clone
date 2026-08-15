import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/features/auth/auth_providers.dart';
import 'package:spotify_clone/features/playlists/models/playlist.dart';
import 'package:spotify_clone/features/playlists/playlists_repository.dart';
import 'package:spotify_clone/features/tracks/track.dart';

final playlistsRepositoryProvider = Provider<PlaylistsRepository>((ref) {
  return PlaylistsRepository(ref.watch(apiClientProvider));
});

final userPlaylistsProvider = FutureProvider<List<Playlist>>((ref) async {
  final repo = ref.watch(playlistsRepositoryProvider);
  return repo.fetchUserPlaylists();
});

final playlistDetailProvider =
    FutureProvider.family<PlaylistDetail, String>((ref, id) async {
  final repo = ref.watch(playlistsRepositoryProvider);
  return repo.fetchPlaylistDetails(id);
});

final likedTracksProvider =
    StateNotifierProvider<LikedTracksNotifier, AsyncValue<List<Track>>>((ref) {
  return LikedTracksNotifier(ref.watch(playlistsRepositoryProvider));
});

class LikedTracksNotifier extends StateNotifier<AsyncValue<List<Track>>> {
  LikedTracksNotifier(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  final PlaylistsRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final tracks = await _repository.fetchLikedTracks();
      state = AsyncValue.data(tracks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  bool isLiked(String trackId) {
    return state.value?.any((t) => t.id == trackId) ?? false;
  }

  Future<void> toggleLike(Track track) async {
    final current = state.value ?? [];
    final alreadyLiked = current.any((t) => t.id == track.id);

    if (alreadyLiked) {
      state = AsyncValue.data(current.where((t) => t.id != track.id).toList());
      try {
        await _repository.unlikeTrack(track.id);
      } catch (e) {
        state = AsyncValue.data(current);
      }
    } else {
      state = AsyncValue.data([track, ...current]);
      try {
        await _repository.likeTrack(track.id);
      } catch (e) {
        state = AsyncValue.data(current);
      }
    }
  }
}
