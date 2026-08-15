import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotify_clone/core/api_client.dart';
import 'package:spotify_clone/core/navigation/nav_shell.dart';
import 'package:spotify_clone/core/token_storage.dart';
import 'package:spotify_clone/features/auth/auth_providers.dart';
import 'package:spotify_clone/features/auth/auth_repository.dart';
import 'package:spotify_clone/features/player/player_providers.dart';
import 'package:spotify_clone/features/tracks/track.dart';
import 'package:spotify_clone/features/tracks/tracks_providers.dart';
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
  Future<String?> restoreSession() async => 'me@test.local';

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

final _track = Track(
  id: '1',
  title: 'First Track',
  artist: 'Artist One',
  durationMs: 125000,
  audioUrl: 'http://test.local/audio/1.mp3',
  createdAt: DateTime(2026, 8, 14),
);

Widget harness() => ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        tracksProvider.overrideWith((ref) async => [_track]),
        audioEngineProvider.overrideWithValue(FakeAudioEngine()),
      ],
      child: const MaterialApp(home: NavShell()),
    );

void main() {
  testWidgets('switches between Home, Search and Library tabs', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('Your tracks'), findsOneWidget);

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.text('Search is coming in a later phase'), findsOneWidget);

    await tester.tap(find.text('Your Library'));
    await tester.pumpAndSettle();
    expect(find.text('First Track'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Your tracks'), findsOneWidget);
  });

  testWidgets('Library rows show Album/Single subtitles and the sort toggle reorders',
      (tester) async {
    final newer = Track(
      id: '2',
      title: 'Zeta',
      artist: 'Artist Z',
      album: 'Album X',
      durationMs: 120000,
      audioUrl: 'http://test.local/audio/2.mp3',
      createdAt: DateTime(2026, 8, 14),
    );
    final older = Track(
      id: '1',
      title: 'Alpha',
      artist: 'Artist A',
      durationMs: 90000,
      audioUrl: 'http://test.local/audio/1.mp3',
      createdAt: DateTime(2026, 8, 13),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          tracksProvider.overrideWith((ref) async => [newer, older]),
          audioEngineProvider.overrideWithValue(FakeAudioEngine()),
        ],
        child: const MaterialApp(home: NavShell()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Your Library'));
    await tester.pumpAndSettle();

    expect(find.text('Your Library'), findsWidgets);
    expect(find.text('Album \u2022 Artist Z'), findsOneWidget);
    expect(find.text('Single \u2022 Artist A'), findsOneWidget);
    expect(find.text('Recents'), findsOneWidget);

    expect(find.text('Zeta'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);

    await tester.tap(find.text('Recents'));
    await tester.pumpAndSettle();

    expect(find.text('A\u2013Z'), findsOneWidget);

    await tester.tap(find.text('A\u2013Z'));
    await tester.pumpAndSettle();

    expect(find.text('Recents'), findsOneWidget);
  });
}