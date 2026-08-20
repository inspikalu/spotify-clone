import 'package:spotify_clone/features/tracks/track.dart';

class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.trackCount,
    required this.coverUrls,
    required this.createdAt,
    this.ownerDisplayName,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final rawCovers = json['coverUrls'] as List<dynamic>? ?? [];
    final owner = json['owner'] as Map<String, dynamic>?;
    return Playlist(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ?? '',
      trackCount: (json['trackCount'] as num?)?.toInt() ?? 0,
      coverUrls: rawCovers.map((e) => e.toString()).toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      ownerDisplayName: json['ownerDisplayName']?.toString() ??
          owner?['displayName']?.toString() ??
          owner?['email']?.toString(),
    );
  }

  final String id;
  final String name;
  final String ownerId;
  final int trackCount;
  final List<String> coverUrls;
  final DateTime createdAt;
  final String? ownerDisplayName;
}

class PlaylistDetail {
  const PlaylistDetail({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.trackCount,
    required this.tracks,
    required this.createdAt,
    this.ownerDisplayName,
  });

  factory PlaylistDetail.fromJson(Map<String, dynamic> json) {
    final rawTracks = json['tracks'] as List<dynamic>? ?? [];
    final owner = json['owner'] as Map<String, dynamic>?;
    return PlaylistDetail(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ?? '',
      trackCount: (json['trackCount'] as num?)?.toInt() ?? rawTracks.length,
      tracks: rawTracks
          .whereType<Map<String, dynamic>>()
          .map((item) => Track.fromJson(item))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      ownerDisplayName: owner?['displayName']?.toString() ?? owner?['email']?.toString(),
    );
  }

  final String id;
  final String name;
  final String ownerId;
  final int trackCount;
  final List<Track> tracks;
  final DateTime createdAt;
  final String? ownerDisplayName;
}
