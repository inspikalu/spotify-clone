import 'package:spotify_clone/features/playlists/models/playlist.dart';
import 'package:spotify_clone/features/tracks/track.dart';

class SearchResults {
  const SearchResults({
    required this.tracks,
    required this.playlists,
    required this.artists,
    required this.albums,
  });

  factory SearchResults.empty() => const SearchResults(
        tracks: [],
        playlists: [],
        artists: [],
        albums: [],
      );

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    final rawTracks = json['tracks'] as List<dynamic>? ?? [];
    final rawPlaylists = json['playlists'] as List<dynamic>? ?? [];
    final rawArtists = json['artists'] as List<dynamic>? ?? [];
    final rawAlbums = json['albums'] as List<dynamic>? ?? [];

    return SearchResults(
      tracks: rawTracks
          .whereType<Map<String, dynamic>>()
          .map((item) => Track.fromJson(item))
          .toList(),
      playlists: rawPlaylists
          .whereType<Map<String, dynamic>>()
          .map((item) => Playlist.fromJson(item))
          .toList(),
      artists: rawArtists.map((e) => e.toString()).toList(),
      albums: rawAlbums.map((e) => e.toString()).toList(),
    );
  }

  final List<Track> tracks;
  final List<Playlist> playlists;
  final List<String> artists;
  final List<String> albums;

  bool get isEmpty =>
      tracks.isEmpty && playlists.isEmpty && artists.isEmpty && albums.isEmpty;
  bool get isNotEmpty => !isEmpty;
}
