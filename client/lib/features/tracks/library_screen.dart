import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/core/errors.dart';
import 'package:spotify_clone/features/tracks/track.dart';
import 'package:spotify_clone/features/tracks/tracks_providers.dart';
import 'package:spotify_clone/features/tracks/upload_track_screen.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(tracksProvider);
    await ref.read(tracksProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(tracksProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
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
        AsyncData(:final value) => RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: value.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final track = value[index];
                return ListTile(
                  leading: _TrackCover(track: track),
                  title: Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: track.durationLabel.isEmpty
                      ? null
                      : Text(track.durationLabel),
                );
              },
            ),
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
    if (coverUrl == null) {
      return CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.music_note,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: coverUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.music_note,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
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