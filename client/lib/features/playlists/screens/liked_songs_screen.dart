import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/features/player/now_playing_screen.dart';
import 'package:spotify_clone/features/player/player_providers.dart';
import 'package:spotify_clone/features/playlists/playlists_providers.dart';
import 'package:spotify_clone/features/playlists/widgets/track_options_sheet.dart';

class LikedSongsScreen extends ConsumerWidget {
  const LikedSongsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedAsync = ref.watch(likedTracksProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: switch (likedAsync) {
        AsyncData(:final value) => CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: const Color(0xFF450AF5),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF450AF5), Color(0xFF191414)],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF450AF5), Color(0xFF8E8EE5)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.favorite, size: 64, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Liked Songs',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${value.length} songs',
                          style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shuffle, color: Color(0xFFB3B3B3), size: 28),
                        onPressed: () {},
                      ),
                      const Spacer(),
                      if (value.isNotEmpty)
                        FloatingActionButton(
                          backgroundColor: const Color(0xFF1DB954),
                          onPressed: () {
                            ref
                                .read(playbackControllerProvider.notifier)
                                .playTrack(value.first, value);
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
                            );
                          },
                          child: const Icon(Icons.play_arrow, color: Colors.black, size: 32),
                        ),
                    ],
                  ),
                ),
              ),
              if (value.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Songs you like will appear here.',
                      style: TextStyle(color: Color(0xFFB3B3B3)),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final track = value[index];
                      final cover = track.coverUrl;
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: cover != null && cover.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: cover,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) => Container(
                                    color: const Color(0xFF282828),
                                    child: const Icon(Icons.music_note, color: Colors.white54),
                                  ),
                                  errorWidget: (_, _, _) => Container(
                                    color: const Color(0xFF282828),
                                    child: const Icon(Icons.music_note, color: Colors.white54),
                                  ),
                                )
                              : Container(
                                  width: 48,
                                  height: 48,
                                  color: const Color(0xFF282828),
                                  child: const Icon(Icons.music_note, color: Colors.white54),
                                ),
                        ),
                        title: Text(
                          track.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          track.artist,
                          style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert, color: Color(0xFFB3B3B3)),
                          onPressed: () => showTrackOptionsSheet(context, ref, track),
                        ),
                        onTap: () {
                          ref
                              .read(playbackControllerProvider.notifier)
                              .playTrack(track, value);
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
                          );
                        },
                      );
                    },
                    childCount: value.length,
                  ),
                ),
            ],
          ),
        AsyncError(:final error) => Scaffold(
            appBar: AppBar(backgroundColor: Colors.black),
            body: Center(
              child: Text(
                'Error loading liked songs: $error',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        _ => const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          ),
      },
    );
  }
}
