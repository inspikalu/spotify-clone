import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/core/color_extractor.dart';
import 'package:spotify_clone/features/player/playback_controller.dart'
    as playback;
import 'package:spotify_clone/features/player/player_providers.dart';
import 'package:spotify_clone/features/playlists/playlists_providers.dart';
import 'package:spotify_clone/features/playlists/widgets/add_to_playlist_modal.dart';
import 'package:spotify_clone/features/playlists/widgets/track_options_sheet.dart';

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
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(
          child: Text('Nothing playing', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

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

    final ambientColor = ambientColorFromSeed(track.id);

    return Scaffold(
      backgroundColor: ambientColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: ambientGradient(track.id),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Top Bar: Down chevron | Context header | Three dots ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 36, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'PLAYING FROM PLAYLIST',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  track.album != null && track.album!.isNotEmpty
                                      ? track.album!
                                      : 'Liked Songs',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert, color: Colors.white),
                              onPressed: () => showTrackOptionsSheet(context, ref, track),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // ── Album Artwork Card ──────────────────────────────────
                        Center(
                          child: Container(
                            constraints: const BoxConstraints(
                              maxWidth: 320,
                              maxHeight: 320,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 24,
                                  offset: Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: AspectRatio(
                                aspectRatio: 1.0,
                                child: coverUrl == null
                                    ? Container(
                                        color: const Color(0xFF3E3E3E),
                                        child: const Icon(
                                          Icons.music_note,
                                          size: 100,
                                          color: Colors.white54,
                                        ),
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: coverUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (_, _) => Container(color: const Color(0xFF3E3E3E)),
                                        errorWidget: (_, _, _) => Container(
                                          color: const Color(0xFF3E3E3E),
                                          child: const Icon(Icons.music_note, size: 100, color: Colors.white54),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Track Title, Artist, and Add/Like Action Icon ─────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    track.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.3,
                                    ),
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
                                    style: const TextStyle(
                                      color: Color(0xFFB3B3B3),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Consumer(
                              builder: (context, ref, _) {
                                final likedState = ref.watch(likedTracksProvider);
                                final isLiked =
                                    likedState.value?.any((t) => t.id == track.id) ?? false;
                                return GestureDetector(
                                  onTap: () => showAddToPlaylistModal(context, ref, track),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isLiked ? const Color(0xFF1DB954) : Colors.transparent,
                                      border: isLiked
                                          ? null
                                          : Border.all(color: const Color(0xFFB3B3B3), width: 2),
                                    ),
                                    child: Icon(
                                      isLiked ? Icons.check : Icons.add,
                                      color: isLiked ? Colors.black : const Color(0xFFB3B3B3),
                                      size: 20,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // ── Progress Scrubber Slider ─────────────────────────────
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3.5,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                            thumbColor: Colors.white,
                            overlayColor: Colors.white24,
                          ),
                          child: Slider(
                            value: sliderValue,
                            max: sliderMax,
                            onChanged: duration == null
                                ? null
                                : (value) => controller.seek(Duration(milliseconds: value.round())),
                          ),
                        ),

                        // ── Timestamp Row ────────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
                              ),
                              Text(
                                duration == null ? '0:00' : _formatDuration(duration),
                                style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Playback Controls ────────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.shuffle,
                                color: shuffle ? const Color(0xFF1DB954) : Colors.white,
                                size: 26,
                              ),
                              onPressed: controller.toggleShuffle,
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_previous_rounded, size: 38, color: Colors.white),
                              onPressed: controller.previous,
                            ),
                            GestureDetector(
                              onTap: controller.togglePlayPause,
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: Icon(
                                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  size: 38,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_next_rounded, size: 38, color: Colors.white),
                              onPressed: controller.next,
                            ),
                            IconButton(
                              icon: Icon(
                                repeat == playback.RepeatMode.one
                                    ? Icons.repeat_one
                                    : Icons.repeat,
                                color: repeat == playback.RepeatMode.off
                                    ? Colors.white
                                    : const Color(0xFF1DB954),
                                size: 26,
                              ),
                              onPressed: controller.cycleRepeat,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // ── Bottom Utility Row ───────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.devices, color: Colors.white70, size: 20),
                              onPressed: () {},
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.share_outlined, color: Colors.white70, size: 20),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.queue_music, color: Colors.white70, size: 22),
                              onPressed: () => showAddToPlaylistModal(context, ref, track),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}