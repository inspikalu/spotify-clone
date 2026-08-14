class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.durationMs,
    this.coverUrl,
    required this.audioUrl,
    required this.createdAt,
  });

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        id: json['id'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String,
        album: json['album'] as String?,
        durationMs: json['durationMs'] as int?,
        coverUrl: json['coverUrl'] as String?,
        audioUrl: json['audioUrl'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final String id;
  final String title;
  final String artist;
  final String? album;
  final int? durationMs;
  final String? coverUrl;
  final String audioUrl;
  final DateTime createdAt;

  String get durationLabel {
    final ms = durationMs;
    if (ms == null) {
      return '';
    }
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}