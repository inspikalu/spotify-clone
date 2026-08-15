import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotify_clone/core/color_extractor.dart';
import 'package:spotify_clone/features/player/now_playing_screen.dart';
import 'package:spotify_clone/features/player/player_providers.dart';
import 'package:spotify_clone/features/playlists/playlists_providers.dart';
import 'fakes.dart';

void main() {
  testWidgets('renders track metadata and controls from state', (tester) async {
    final engine = FakeAudioEngine();
    final container = ProviderContainer(
      overrides: [
        audioEngineProvider.overrideWithValue(engine),
        randomProvider.overrideWithValue(Random(42)),
        likedTracksProvider.overrideWith((ref) => LikedTracksNotifier.empty()),
      ],
    );
    addTearDown(container.dispose);
    final track = testTrack('1', durationMs: 180000, album: 'Album One');
    await container
        .read(playbackControllerProvider.notifier)
        .playTrack(track, [track]);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NowPlayingScreen()),
      ),
    );
    engine.playingAt(0);
    engine.durationController.add(const Duration(seconds: 180));
    await tester.pump();

    expect(find.text('Track 1'), findsOneWidget);
    expect(find.text('Artist 1 · Album One'), findsOneWidget);
    expect(find.text('3:00'), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(find.byIcon(Icons.shuffle), findsOneWidget);
    expect(find.byIcon(Icons.repeat), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('dragging the slider seeks on the engine', (tester) async {
    final engine = FakeAudioEngine();
    final container = ProviderContainer(
      overrides: [
        audioEngineProvider.overrideWithValue(engine),
        randomProvider.overrideWithValue(Random(42)),
        likedTracksProvider.overrideWith((ref) => LikedTracksNotifier.empty()),
      ],
    );
    addTearDown(container.dispose);
    final track = testTrack('1', durationMs: 180000);
    await container
        .read(playbackControllerProvider.notifier)
        .playTrack(track, [track]);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NowPlayingScreen()),
      ),
    );
    engine.playingAt(0);
    engine.durationController.add(const Duration(seconds: 180));
    await tester.pump();

    await tester.drag(find.byType(Slider), const Offset(200, 0));
    await tester.pump();

    final lastSeek = engine.lastSeek;
    expect(lastSeek, isNotNull);
    expect(lastSeek, greaterThan(const Duration(seconds: 10)));
    expect(lastSeek, lessThanOrEqualTo(const Duration(seconds: 180)));
  });

  testWidgets('NowPlayingScreen background uses dynamic ambient gradient from track id',
      (tester) async {
    final engine = FakeAudioEngine();
    final container = ProviderContainer(
      overrides: [
        audioEngineProvider.overrideWithValue(engine),
        randomProvider.overrideWithValue(Random(42)),
        likedTracksProvider.overrideWith((ref) => LikedTracksNotifier.empty()),
      ],
    );
    addTearDown(container.dispose);
    final track = testTrack('ambient-test', durationMs: 180000);
    await container
        .read(playbackControllerProvider.notifier)
        .playTrack(track, [track]);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NowPlayingScreen()),
      ),
    );
    engine.playingAt(0);
    await tester.pump();

    // The scaffold background should be the ambient color from the track id
    final expectedColor = ambientColorFromSeed(track.id);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, equals(expectedColor));

    // Must NOT be the old static brown color
    expect(expectedColor, isNot(equals(const Color(0xFF2A1508))));
  });
}