import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/features/player/playback_controller.dart'
    as playback;
import 'package:spotify_clone/features/player/player_providers.dart';

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider);
    if (track == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Nothing playing')),
      );
    }
    final theme = Theme.of(context);
    final controller = ref.read(playbackControllerProvider.notifier);
    final isPlaying = ref.watch(isPlayingProvider);
    final position = ref.watch(positionProvider);
    final duration = ref.watch(playbackControllerProvider).duration;
    final shuffle = ref.watch(shuffleProvider);
    final repeat = ref.watch(repeatModeProvider);
    final coverUrl = track.coverUrl;
    final sliderMax = duration == null
        ? 0.0
        : duration.inMilliseconds.clamp(0, 1 << 31).toDouble();
    final sliderValue = duration == null
        ? 0.0
        : position.inMilliseconds.clamp(0, sliderMax).toDouble();

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: coverUrl == null
                    ? Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.music_note,
                          size: 96,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: coverUrl,
                          width: 280,
                          height: 280,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(
                            width: 280,
                            height: 280,
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                          errorWidget: (_, _, _) => Container(
                            width: 280,
                            height: 280,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.music_note,
                              size: 96,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      track.artist,
                      if (track.album != null && track.album!.isNotEmpty)
                        track.album!,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Slider(
                    value: sliderValue,
                    max: sliderMax,
                    onChanged: duration == null
                        ? null
                        : (value) =>
                            controller.seek(Duration(milliseconds: value.round())),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          duration == null
                              ? ''
                              : _formatDuration(duration),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        tooltip: 'Shuffle',
                        icon: Icon(
                          Icons.shuffle,
                          color: shuffle
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        onPressed: controller.toggleShuffle,
                      ),
                      IconButton(
                        tooltip: 'Previous',
                        icon: const Icon(Icons.skip_previous_rounded, size: 40),
                        onPressed: controller.previous,
                      ),
                      IconButton.filled(
                        tooltip: isPlaying ? 'Pause' : 'Play',
                        iconSize: 44,
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        onPressed: controller.togglePlayPause,
                      ),
                      IconButton(
                        tooltip: 'Next',
                        icon: const Icon(Icons.skip_next_rounded, size: 40),
                        onPressed: controller.next,
                      ),
                      IconButton(
                        tooltip: 'Repeat',
                        icon: Icon(
                          repeat == playback.RepeatMode.one
                              ? Icons.repeat_one
                              : Icons.repeat,
                          color: repeat == playback.RepeatMode.off
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.primary,
                        ),
                        onPressed: controller.cycleRepeat,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}