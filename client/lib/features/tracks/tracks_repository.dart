import 'package:dio/dio.dart';
import 'package:spotify_clone/core/api_client.dart';
import 'package:spotify_clone/features/tracks/track.dart';

class TracksRepository {
  TracksRepository(this._api);

  final ApiClient _api;

  Future<List<Track>> fetchTracks() async {
    final response = await _api.get('/tracks');
    final data = response.data as List<dynamic>;
    return data
        .map((item) => Track.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> uploadTrack({
    required String title,
    required String artist,
    String? album,
    required String audioPath,
    String? audioName,
    String? coverPath,
    ProgressCallback? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'title': title,
      'artist': artist,
      if (album != null && album.isNotEmpty) 'album': album,
      'file': await MultipartFile.fromFile(audioPath, filename: audioName),
      if (coverPath != null)
        'cover': await MultipartFile.fromFile(coverPath),
    });
    await _api.postMultipart('/tracks', formData, onSendProgress: onProgress);
  }
}