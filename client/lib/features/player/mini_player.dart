import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/features/player/now_playing_screen.dart';
import 'package:spotify_clone/features/player/player_providers.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider);
    if (track == null) {
      return const SizedBox.shrink();
    }
    final isPlaying = ref.watch(isPlayingProvider);
    final theme = Theme.of(context);
    final coverUrl = track.coverUrl;
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
        ),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 8),
              if (coverUrl == null)
                CircleAvatar(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.music_note,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: coverUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.music_note,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isPlaying ? 'Pause' : 'Play',
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 32,
                ),
                onPressed: () =>
                    ref.read(playbackControllerProvider.notifier).togglePlayPause(),
              ),
              IconButton(
                tooltip: 'Next',
                icon: const Icon(Icons.skip_next_rounded),
                onPressed: () =>
                    ref.read(playbackControllerProvider.notifier).next(),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}