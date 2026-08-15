import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/core/token_storage.dart';
import 'package:spotify_clone/features/auth/auth_providers.dart';
import 'package:spotify_clone/features/tracks/track.dart';
import 'package:spotify_clone/features/tracks/tracks_providers.dart';

class RecentlyPlayedNotifier extends StateNotifier<List<String>> {
  RecentlyPlayedNotifier(this._storage) : super([]) {
    load();
  }

  final TokenStorage _storage;
  static const _storageKey = 'recently_played_ids';
  static const _maxItems = 10;

  Future<void> load() async {
    final raw = await _storage.read(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list =
            (jsonDecode(raw) as List<dynamic>).map((e) => e.toString()).toList();
        state = list;
      } catch (_) {
        state = [];
      }
    }
  }

  Future<void> addTrack(String trackId) async {
    final updated = [
      trackId,
      ...state.where((id) => id != trackId),
    ];
    final capped = updated.take(_maxItems).toList();
    state = capped;
    await _storage.write(_storageKey, jsonEncode(capped));
  }

  Future<void> clear() async {
    state = [];
    await _storage.delete(_storageKey);
  }
}

final recentlyPlayedNotifierProvider =
    StateNotifierProvider<RecentlyPlayedNotifier, List<String>>((ref) {
  return RecentlyPlayedNotifier(ref.watch(tokenStorageProvider));
});

/// Resolves recently-played IDs into full Track objects from the catalog.
/// Returns a Future list so callers can use FutureProvider.family or watch it.
final recentlyPlayedTracksProvider = FutureProvider<List<Track>>((ref) async {
  final ids = ref.watch(recentlyPlayedNotifierProvider);
  if (ids.isEmpty) return [];
  final allTracks = await ref.watch(tracksProvider.future);
  final trackMap = {for (final t in allTracks) t.id: t};
  return ids
      .map((id) => trackMap[id])
      .whereType<Track>()
      .toList();
});
