import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/features/player/now_playing_screen.dart';
import 'package:spotify_clone/features/player/player_providers.dart';
import 'package:spotify_clone/features/playlists/playlists_providers.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider);
    if (track == null) {
      return const SizedBox.shrink();
    }
    final isPlaying = ref.watch(isPlayingProvider);
    final coverUrl = track.coverUrl;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
      ),
      child: Container(
        height: 64,
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
        decoration: BoxDecoration(
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // Album art
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              child: SizedBox(
                width: 52,
                height: 52,
                child: coverUrl == null
                    ? Container(
                        color: const Color(0xFF3E3E3E),
                        child: const Icon(
                          Icons.music_note,
                          color: Color(0xFFB3B3B3),
                          size: 24,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: coverUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Container(
                          color: const Color(0xFF3E3E3E),
                          child: const Icon(
                            Icons.music_note,
                            color: Color(0xFFB3B3B3),
                            size: 24,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            // Title + artist
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFB3B3B3),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Controls
            Consumer(
              builder: (context, ref, _) {
                final isLiked =
                    ref.watch(likedTracksProvider.notifier).isLiked(track.id);
                return IconButton(
                  tooltip: isLiked ? 'Liked' : 'Like',
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? const Color(0xFF1DB954) : Colors.white,
                    size: 24,
                  ),
                  onPressed: () =>
                      ref.read(likedTracksProvider.notifier).toggleLike(track),
                );
              },
            ),
            IconButton(
              tooltip: isPlaying ? 'Pause' : 'Play',
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 32,
              ),
              onPressed: () =>
                  ref.read(playbackControllerProvider.notifier).togglePlayPause(),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}