import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:spotify_clone/core/token_storage.dart';
import 'package:spotify_clone/features/home/providers/recently_played_provider.dart';

void main() {
  group('RecentlyPlayedNotifier', () {
    test('starts empty', () {
      final notifier = RecentlyPlayedNotifier(MemoryTokenStorage());
      expect(notifier.state, isEmpty);
    });

    test('addTrack appends to front and persists to storage', () async {
      final storage = MemoryTokenStorage();
      final notifier = RecentlyPlayedNotifier(storage);
      await notifier.addTrack('track-1');
      await notifier.addTrack('track-2');

      expect(notifier.state, ['track-2', 'track-1']);
      final raw = await storage.read('recently_played_ids');
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as List;
      expect(decoded, ['track-2', 'track-1']);
    });

    test('addTrack deduplicates — moving existing ID to front', () async {
      final notifier = RecentlyPlayedNotifier(MemoryTokenStorage());
      await notifier.addTrack('track-a');
      await notifier.addTrack('track-b');
      await notifier.addTrack('track-a'); // duplicate

      expect(notifier.state, ['track-a', 'track-b']);
    });

    test('addTrack caps at 10 items', () async {
      final notifier = RecentlyPlayedNotifier(MemoryTokenStorage());
      for (var i = 1; i <= 12; i++) {
        await notifier.addTrack('track-$i');
      }

      expect(notifier.state.length, 10);
      // most-recent first
      expect(notifier.state.first, 'track-12');
    });

    test('load restores state from storage', () async {
      final storage = MemoryTokenStorage();
      // pre-seed storage
      await storage.write(
          'recently_played_ids', jsonEncode(['id-x', 'id-y']));

      final notifier = RecentlyPlayedNotifier(storage);
      // wait for async load
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state, ['id-x', 'id-y']);
    });
  });
}
