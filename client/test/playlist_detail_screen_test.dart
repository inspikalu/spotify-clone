import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotify_clone/core/color_extractor.dart';
import 'package:spotify_clone/features/playlists/models/playlist.dart';
import 'package:spotify_clone/features/playlists/playlists_providers.dart';
import 'package:spotify_clone/features/playlists/screens/liked_songs_screen.dart';
import 'package:spotify_clone/features/playlists/screens/playlist_detail_screen.dart';
import 'package:spotify_clone/features/tracks/track.dart';

void main() {
  final sampleTrack = Track(
    id: 't1',
    title: 'Apala Interlude',
    artist: 'Seyi Vibez',
    durationMs: 160000,
    audioUrl: 'http://test.local/1.mp3',
    createdAt: DateTime.now(),
  );

  final samplePlaylist = PlaylistDetail(
    id: 'p1',
    name: 'Top Hits',
    ownerId: 'u1',
    ownerDisplayName: 'Admin',
    trackCount: 1,
    tracks: [sampleTrack],
    createdAt: DateTime.now(),
  );

  testWidgets('PlaylistDetailScreen renders header, creator and tracks', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playlistDetailProvider('p1').overrideWith((ref) => samplePlaylist),
        ],
        child: const MaterialApp(
          home: PlaylistDetailScreen(playlistId: 'p1', initialName: 'Top Hits'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Top Hits'), findsOneWidget);
    expect(find.text('Admin • 1 songs'), findsOneWidget);
    expect(find.text('Apala Interlude'), findsOneWidget);
    expect(find.text('Seyi Vibez'), findsOneWidget);
  });

  testWidgets('PlaylistDetailScreen uses ambient gradient derived from playlist ID',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playlistDetailProvider('p1').overrideWith((ref) => samplePlaylist),
        ],
        child: const MaterialApp(
          home: PlaylistDetailScreen(playlistId: 'p1', initialName: 'Top Hits'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // ambientColorFromSeed('p1') must NOT be the old static blue Color(0xFF1E3264)
    final expectedAmbient = ambientColorFromSeed('p1');
    expect(expectedAmbient, isNot(equals(const Color(0xFF1E3264))));

    // Verify the SliverAppBar backgroundColor matches the ambient seed
    final sliverAppBar = tester.widget<SliverAppBar>(find.byType(SliverAppBar).first);
    expect(sliverAppBar.backgroundColor, equals(expectedAmbient));
  });

  testWidgets('LikedSongsScreen renders liked songs list', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          likedTracksProvider.overrideWith(
            (ref) => _FakeLikedNotifier([sampleTrack]),
          ),
        ],
        child: const MaterialApp(
          home: LikedSongsScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // "Liked Songs" appears in both the collapsed appbar title and the
    // expanded FlexibleSpaceBar — findsWidgets covers both.
    expect(find.text('Liked Songs'), findsWidgets);
    expect(find.text('1 songs'), findsOneWidget);
    expect(find.text('Apala Interlude'), findsOneWidget);
  });
}

class _FakeLikedNotifier extends StateNotifier<AsyncValue<List<Track>>>
    implements LikedTracksNotifier {
  _FakeLikedNotifier(List<Track> initial) : super(AsyncValue.data(initial));

  @override
  bool isLiked(String trackId) => state.value?.any((t) => t.id == trackId) ?? false;

  @override
  Future<void> load() async {}

  @override
  Future<void> toggleLike(Track track) async {}
}
