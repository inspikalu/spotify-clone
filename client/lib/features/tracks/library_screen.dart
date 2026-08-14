import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/core/errors.dart';
import 'package:spotify_clone/features/player/player_providers.dart';
import 'package:spotify_clone/features/tracks/track.dart';
import 'package:spotify_clone/features/tracks/tracks_providers.dart';
import 'package:spotify_clone/features/tracks/upload_track_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  bool _sortAz = false;

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(tracksProvider);
    await ref.read(tracksProvider.future);
  }

  List<Track> _sorted(List<Track> tracks) {
    if (!_sortAz) {
      return tracks;
    }
    final sorted = [...tracks];
    sorted.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final tracksAsync = ref.watch(tracksProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Library'),
        actions: [
          IconButton(
            tooltip: 'Upload track',
            icon: const Icon(Icons.add),
            onPressed: () async {
              final uploaded = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const UploadTrackScreen(),
                ),
              );
              if (uploaded == true) {
                ref.invalidate(tracksProvider);
              }
            },
          ),
        ],
      ),
      body: switch (tracksAsync) {
        AsyncData(:final value) when value.isEmpty => const _EmptyLibrary(),
        AsyncData(:final value) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: TextButton.icon(
                  onPressed: () => setState(() => _sortAz = !_sortAz),
                  icon: const Icon(Icons.swap_vert, size: 16),
                  label: Text(
                    _sortAz ? '↓↑ A–Z' : '↓↑ Recents',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _refresh(ref),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: value.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final track = _sorted(value)[index];
                      return ListTile(
                        onTap: () => ref
                            .read(playbackControllerProvider.notifier)
                            .playTrack(track, value),
                        leading: _TrackCover(track: track),
                        title: Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          track.album == null
                              ? 'Single • ${track.artist}'
                              : 'Album • ${track.artist}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFB3B3B3),
                            fontSize: 13,
                          ),
                        ),
                        trailing: track.durationLabel.isEmpty
                            ? null
                            : Text(
                                track.durationLabel,
                                style: const TextStyle(
                                  color: Color(0xFFB3B3B3),
                                  fontSize: 13,
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        AsyncError(:final error) => _LibraryError(
            message: apiErrorMessage(error),
            onRetry: () => ref.invalidate(tracksProvider),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final uploaded = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const UploadTrackScreen(),
            ),
          );
          if (uploaded == true) {
            ref.invalidate(tracksProvider);
          }
        },
        icon: const Icon(Icons.upload),
        label: const Text('Upload'),
      ),
    );
  }
}

class _TrackCover extends StatelessWidget {
  const _TrackCover({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final coverUrl = track.coverUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 56,
        height: 56,
        child: coverUrl == null
            ? const _CoverPlaceholder()
            : CachedNetworkImage(
                imageUrl: coverUrl,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const _CoverPlaceholder(),
              ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      color: const Color(0xFF282828),
      child: const Center(
        child: Icon(Icons.music_note, color: Color(0xFFB3B3B3), size: 24),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_music,
            size: 72,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No tracks yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your first track to get started',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LibraryError extends StatelessWidget {
  const _LibraryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 72,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
