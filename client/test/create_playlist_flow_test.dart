import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotify_clone/core/widgets/create_bottom_sheet.dart';
import 'package:spotify_clone/features/playlists/models/playlist.dart';
import 'package:spotify_clone/features/playlists/playlists_providers.dart';
import 'package:spotify_clone/features/playlists/playlists_repository.dart';
import 'package:spotify_clone/features/playlists/widgets/add_to_playlist_modal.dart';
import 'package:spotify_clone/features/tracks/track.dart';

class _FakePlaylistsRepo extends Fake implements PlaylistsRepository {
  final List<String> createdNames = [];
  final List<String> addedTrackIds = [];

  @override
  Future<Playlist> createPlaylist(String name) async {
    createdNames.add(name);
    return Playlist(
      id: 'p-new',
      name: name,
      ownerId: 'u1',
      trackCount: 0,
      coverUrls: [],
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<Playlist>> fetchUserPlaylists() async {
    return [
      Playlist(
        id: 'p1',
        name: 'Chill Vibes',
        ownerId: 'u1',
        trackCount: 3,
        coverUrls: [],
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<void> addTrackToPlaylist(String playlistId, String trackId) async {
    addedTrackIds.add(trackId);
  }
}

void main() {
  testWidgets('Create playlist dialog triggers repo createPlaylist', (tester) async {
    final fakeRepo = _FakePlaylistsRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playlistsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                return ElevatedButton(
                  onPressed: () => showCreateBottomSheet(context, ref),
                  child: const Text('Open Create'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Create'));
    await tester.pumpAndSettle();

    expect(find.text('Playlist'), findsOneWidget);
    await tester.tap(find.text('Playlist'));
    await tester.pumpAndSettle();

    expect(find.text('Give your playlist a name'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'My Summer Jam');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(fakeRepo.createdNames, contains('My Summer Jam'));
  });

  testWidgets('Add to playlist modal lists playlists and adds track', (tester) async {
    final fakeRepo = _FakePlaylistsRepo();
    final sampleTrack = Track(
      id: 't1',
      title: 'Track 1',
      artist: 'Artist 1',
      audioUrl: 'http://test.local/1.mp3',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playlistsRepositoryProvider.overrideWithValue(fakeRepo),
          userPlaylistsProvider.overrideWith((ref) => fakeRepo.fetchUserPlaylists()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                return ElevatedButton(
                  onPressed: () => showAddToPlaylistModal(context, ref, sampleTrack),
                  child: const Text('Open Add Modal'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Add Modal'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Chill Vibes'), findsOneWidget);
    await tester.tap(find.text('Chill Vibes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(fakeRepo.addedTrackIds, contains('t1'));
  });
}
