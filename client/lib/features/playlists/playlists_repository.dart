import 'package:spotify_clone/core/api_client.dart';
import 'package:spotify_clone/features/playlists/models/playlist.dart';
import 'package:spotify_clone/features/tracks/track.dart';

class PlaylistsRepository {
  PlaylistsRepository(this._api);

  final ApiClient _api;

  Future<List<Playlist>> fetchUserPlaylists() async {
    final response = await _api.get('/playlists');
    final data = response.data as List<dynamic>;
    return data
        .map((item) => Playlist.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PlaylistDetail> fetchPlaylistDetails(String playlistId) async {
    final response = await _api.get('/playlists/$playlistId');
    return PlaylistDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Playlist> createPlaylist(String name) async {
    final response = await _api.post('/playlists', data: {'name': name});
    return Playlist.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    await _api.patch('/playlists/$playlistId', data: {'name': newName});
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _api.delete('/playlists/$playlistId');
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackId) async {
    await _api.post('/playlists/$playlistId/tracks', data: {'trackId': trackId});
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) async {
    await _api.delete('/playlists/$playlistId/tracks/$trackId');
  }

  Future<void> likeTrack(String trackId) async {
    await _api.post('/tracks/$trackId/like');
  }

  Future<void> unlikeTrack(String trackId) async {
    await _api.delete('/tracks/$trackId/like');
  }

  Future<List<Track>> fetchLikedTracks() async {
    final response = await _api.get('/me/liked-tracks');
    final data = response.data as List<dynamic>;
    return data
        .map((item) => Track.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
