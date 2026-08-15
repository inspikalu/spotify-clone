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
}