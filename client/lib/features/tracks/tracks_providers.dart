import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/features/auth/auth_providers.dart';
import 'package:spotify_clone/features/tracks/track.dart';
import 'package:spotify_clone/features/tracks/tracks_repository.dart';

final tracksRepositoryProvider = Provider<TracksRepository>(
  (ref) => TracksRepository(ref.watch(apiClientProvider)),
);

final tracksProvider = FutureProvider<List<Track>>(
  (ref) => ref.watch(tracksRepositoryProvider).fetchTracks(),
);