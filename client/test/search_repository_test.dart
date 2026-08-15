import 'package:flutter_test/flutter_test.dart';
import 'package:spotify_clone/core/token_storage.dart';
import 'package:spotify_clone/features/search/models/search_result.dart';
import 'package:spotify_clone/features/search/search_providers.dart';

void main() {
  test('SearchResults.fromJson parses tracks, playlists, artists, albums', () {
    final json = {
      'tracks': [
        {
          'id': 't1',
          'title': 'Test Song',
          'artist': 'Test Artist',
          'album': 'Test Album',
          'durationMs': 120000,
          'coverUrl': 'http://cover.jpg',
          'audioUrl': 'http://audio.mp3',
          'createdAt': '2026-08-15T00:00:00.000Z',
        }
      ],
      'playlists': [
        {
          'id': 'p1',
          'name': 'Test Playlist',
          'ownerId': 'u1',
          'ownerDisplayName': 'Curator',
          'trackCount': 5,
          'coverUrls': [],
          'createdAt': '2026-08-15T00:00:00.000Z',
        }
      ],
      'artists': ['Test Artist'],
      'albums': ['Test Album'],
    };

    final results = SearchResults.fromJson(json);
    expect(results.tracks, hasLength(1));
    expect(results.tracks.first.title, 'Test Song');
    expect(results.playlists, hasLength(1));
    expect(results.playlists.first.name, 'Test Playlist');
    expect(results.artists, ['Test Artist']);
    expect(results.albums, ['Test Album']);
    expect(results.isNotEmpty, isTrue);
  });

  test('RecentSearchesNotifier adds, caps at 10, removes, and clears queries', () async {
    final storage = MemoryTokenStorage();
    final notifier = RecentSearchesNotifier(storage);

    await notifier.addQuery('Seyi Vibez');
    await notifier.addQuery('Asake');
    await notifier.addQuery('Burna Boy');

    expect(notifier.state, ['Burna Boy', 'Asake', 'Seyi Vibez']);

    // Re-adding moves to top
    await notifier.addQuery('asake');
    expect(notifier.state, ['asake', 'Burna Boy', 'Seyi Vibez']);

    // Remove one
    await notifier.removeQuery('Burna Boy');
    expect(notifier.state, ['asake', 'Seyi Vibez']);

    // Clear all
    await notifier.clearAll();
    expect(notifier.state, isEmpty);
  });
}
