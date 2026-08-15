import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotify_clone/core/api_client.dart';
import 'package:spotify_clone/core/token_storage.dart';
import 'package:spotify_clone/features/auth/auth_providers.dart';
import 'package:spotify_clone/features/auth/auth_repository.dart';
import 'package:spotify_clone/features/player/player_providers.dart';
import 'package:spotify_clone/features/playlists/models/playlist.dart';
import 'package:spotify_clone/features/playlists/playlists_providers.dart';
import 'package:spotify_clone/features/search/models/search_result.dart';
import 'package:spotify_clone/features/search/search_providers.dart';
import 'package:spotify_clone/features/search/search_screen.dart';
import 'package:spotify_clone/features/tracks/track.dart';
import 'fakes.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository()
      : super(
          ApiClient(
            dio: Dio(),
            storage: MemoryTokenStorage(),
            baseUrl: 'http://localhost:1',
          ),
          MemoryTokenStorage(),
        );

  @override
  Future<String?> restoreSession() async => 'user@test.com';

  @override
  Future<void> logIn({required String email, required String password}) async {}

  @override
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {}

  @override
  Future<void> logOut() async {}
}

void main() {
  final sampleTrack = Track(
    id: 't1',
    title: 'Apala Interlude',
    artist: 'Seyi Vibez',
    durationMs: 160000,
    audioUrl: 'http://test.local/1.mp3',
    createdAt: DateTime.now(),
  );

  final samplePlaylist = Playlist(
    id: 'p1',
    name: 'Afro Hits',
    ownerId: 'u1',
    ownerDisplayName: 'Curator',
    trackCount: 10,
    coverUrls: [],
    createdAt: DateTime.now(),
  );

  final sampleResults = SearchResults(
    tracks: [sampleTrack],
    playlists: [samplePlaylist],
    artists: ['Seyi Vibez'],
    albums: ['Billion Dollar Baby'],
  );

  Widget createHarness({String initialQuery = ''}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        audioEngineProvider.overrideWithValue(FakeAudioEngine()),
        likedTracksProvider.overrideWith((ref) => LikedTracksNotifier.empty()),
        searchQueryProvider.overrideWith((ref) => initialQuery),
        searchResultsProvider('seyi').overrideWith((ref) => sampleResults),
        recentSearchesProvider.overrideWith((ref) => _FakeRecentNotifier(['Asake'])),
      ],
      child: const MaterialApp(
        home: SearchScreen(),
      ),
    );
  }

  testWidgets('SearchScreen renders pre-search browse categories and recent searches', (tester) async {
    await tester.pumpWidget(createHarness());
    await tester.pump();

    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Browse all'), findsOneWidget);
    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('Asake'), findsOneWidget);
    expect(find.text('Afrobeats'), findsOneWidget);
  });

  testWidgets('SearchScreen shows categorized results when query matches', (tester) async {
    await tester.pumpWidget(createHarness(initialQuery: 'seyi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Top result'), findsOneWidget);
    expect(find.text('Apala Interlude'), findsWidgets);
    expect(find.text('Afro Hits'), findsOneWidget);
    expect(find.text('Seyi Vibez'), findsWidgets);
  });
}

class _FakeRecentNotifier extends RecentSearchesNotifier {
  _FakeRecentNotifier(List<String> initial) : super(MemoryTokenStorage()) {
    state = initial;
  }
}
