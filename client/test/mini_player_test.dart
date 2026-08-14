import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotify_clone/features/player/mini_player.dart';
import 'package:spotify_clone/features/player/player_providers.dart';
import 'fakes.dart';

void main() {
  testWidgets('with no current track the mini player is absent', (tester) async {
    final container = ProviderContainer(
      overrides: [
        audioEngineProvider.overrideWithValue(FakeAudioEngine()),
        randomProvider.overrideWithValue(Random(42)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: MiniPlayer())),
      ),
    );

    expect(tester.getSize(find.byType(MiniPlayer)), Size.zero);
  });

  testWidgets('with a current track shows title and artist and toggles play',
      (tester) async {
    final engine = FakeAudioEngine();
    final container = ProviderContainer(
      overrides: [
        audioEngineProvider.overrideWithValue(engine),
        randomProvider.overrideWithValue(Random(42)),
      ],
    );
    addTearDown(container.dispose);
    final track = testTrack('1');
    await container
        .read(playbackControllerProvider.notifier)
        .playTrack(track, [track]);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: MiniPlayer())),
      ),
    );
    engine.playingAt(0);
    await tester.pump();

    expect(find.text('Track 1'), findsOneWidget);
    expect(find.text('Artist 1'), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    expect(engine.pauseCalls, 1);

    engine.playerStateController.add(PlayerState(false, ProcessingState.ready));
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    expect(engine.playCalls, 2);
  });
}