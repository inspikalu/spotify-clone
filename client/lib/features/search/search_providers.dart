import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/core/token_storage.dart';
import 'package:spotify_clone/features/auth/auth_providers.dart';
import 'package:spotify_clone/features/search/models/search_result.dart';
import 'package:spotify_clone/features/search/search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepository(ref.watch(apiClientProvider)),
);

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose
    .family<SearchResults, String>((ref, query) async {
  final trimmed = query.trim();
  if (trimmed.isEmpty) {
    return SearchResults.empty();
  }
  return ref.watch(searchRepositoryProvider).search(trimmed);
});

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  RecentSearchesNotifier(this._storage) : super([]) {
    load();
  }

  final TokenStorage _storage;
  static const _storageKey = 'recent_searches_list';

  Future<void> load() async {
    final raw = await _storage.read(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List<dynamic>).map((e) => e.toString()).toList();
        state = list;
      } catch (_) {
        state = [];
      }
    }
  }

  Future<void> addQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final updated = [trimmed, ...state.where((q) => q.toLowerCase() != trimmed.toLowerCase())];
    final capped = updated.take(10).toList();
    state = capped;
    await _storage.write(_storageKey, jsonEncode(capped));
  }

  Future<void> removeQuery(String query) async {
    final updated = state.where((q) => q != query).toList();
    state = updated;
    await _storage.write(_storageKey, jsonEncode(updated));
  }

  Future<void> clearAll() async {
    state = [];
    await _storage.delete(_storageKey);
  }
}

final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<String>>((ref) {
  return RecentSearchesNotifier(ref.watch(tokenStorageProvider));
});
