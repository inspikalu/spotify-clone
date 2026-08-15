import 'package:spotify_clone/core/api_client.dart';
import 'package:spotify_clone/features/search/models/search_result.dart';

class SearchRepository {
  SearchRepository(this._api);

  final ApiClient _api;

  Future<SearchResults> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return SearchResults.empty();
    }
    final encoded = Uri.encodeQueryComponent(trimmed);
    final response = await _api.get('/search?q=$encoded');
    return SearchResults.fromJson(response.data as Map<String, dynamic>);
  }
}
