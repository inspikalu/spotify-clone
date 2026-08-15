import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotify_clone/core/api_client.dart';
import 'package:spotify_clone/core/token_storage.dart';
import 'package:spotify_clone/features/auth/auth_providers.dart';
import 'package:spotify_clone/features/auth/auth_repository.dart';
import 'package:spotify_clone/features/home/home_screen.dart';
import 'package:spotify_clone/features/player/now_playing_screen.dart';
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

Widget _harness(FakeAudioEngine engine, List<Override> overrides) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      audioEngineProvider.overrideWithValue(engine),
      randomProvider.overrideWithValue(Random(42)),
      ...overrides,
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

void main() {
  testWidgets('shows a spinner while tracks load', (tester) async {
    final engine = FakeAudioEngine();
    await tester.pumpWidget(
      _harness(engine, [
        tracksProvider.overrideWith((ref) => Completer<List<Track>>().future),
      ]),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('error state shows the message and Retry reloads', (tester) async {
    final engine = FakeAudioEngine();
    var calls = 0;
    await tester.pumpWidget(
      _harness(engine, [
        tracksProvider.overrideWith((ref) async {
          calls++;
          if (calls == 1) {
            throw Exception('boom');
          }
          return [testTrack('1')];
        }),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Something went wrong'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Track 1'), findsWidgets);
    expect(calls, 2);
  });

  testWidgets('empty state shows the no-tracks message', (tester) async {
    final engine = FakeAudioEngine();
    await tester.pumpWidget(
      _harness(engine, [tracksProvider.overrideWith((ref) async => [])]),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No tracks in your library yet'),
      findsOneWidget,
    );
  });

  testWidgets('shelf renders each track title and artist', (tester) async {
    final engine = FakeAudioEngine();
    await tester.pumpWidget(
      _harness(engine, [
        tracksProvider.overrideWith(
          (ref) async => [testTrack('1'), testTrack('2')],
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your tracks'), findsOneWidget);
    expect(find.text('Track 1'), findsWidgets);
    expect(find.text('Artist 1'), findsWidgets);
    expect(find.text('Track 2'), findsWidgets);
    expect(find.text('Artist 2'), findsWidgets);
  });

  testWidgets('tapping a card plays the track and opens Now Playing',
      (tester) async {
    final engine = FakeAudioEngine();
    await tester.pumpWidget(
      _harness(engine, [
        tracksProvider.overrideWith(
          (ref) async => [testTrack('1')],
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Track 1').first);
    await tester.pumpAndSettle();

    expect(engine.playCalls, 1);
    expect(find.byType(NowPlayingScreen), findsOneWidget);
  });
}
