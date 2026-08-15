import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/core/color_extractor.dart';
import 'package:spotify_clone/features/player/now_playing_screen.dart';
import 'package:spotify_clone/features/player/player_providers.dart';
import 'package:spotify_clone/features/playlists/playlists_providers.dart';
import 'package:spotify_clone/features/playlists/widgets/track_options_sheet.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.initialName,
  });

  final String playlistId;
  final String initialName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistAsync = ref.watch(playlistDetailProvider(playlistId));

    return Scaffold(
      backgroundColor: Colors.black,
      body: switch (playlistAsync) {
        AsyncData(:final value) => CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: ambientColorFromSeed(playlistId),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: ambientGradient(playlistId),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 48),
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: const Color(0xFF282828),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.music_note, size: 64, color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          value.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${value.ownerDisplayName ?? 'User'} • ${value.trackCount} songs',
                          style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showPlaylistMenu(context, ref, value.name),
                  ),
                ],
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
                      if (value.tracks.isNotEmpty)
                        FloatingActionButton(
                          backgroundColor: const Color(0xFF1DB954),
                          onPressed: () {
                            ref
                                .read(playbackControllerProvider.notifier)
                                .playTrack(value.tracks.first, value.tracks);
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
              if (value.tracks.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No songs in this playlist yet.',
                      style: TextStyle(color: Color(0xFFB3B3B3)),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final track = value.tracks[index];
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
                              .playTrack(track, value.tracks);
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
                          );
                        },
                      );
                    },
                    childCount: value.tracks.length,
                  ),
                ),
            ],
          ),
        AsyncError(:final error) => Scaffold(
            appBar: AppBar(backgroundColor: Colors.black),
            body: Center(
              child: Text(
                'Error loading playlist: $error',
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

  void _showPlaylistMenu(BuildContext context, WidgetRef ref, String currentName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white),
                title: const Text('Rename playlist', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRenameDialog(context, ref, currentName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Delete playlist', style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(context);
                  Navigator.pop(ctx);
                  try {
                    await ref.read(playlistsRepositoryProvider).deletePlaylist(playlistId);
                    ref.invalidate(userPlaylistsProvider);
                    nav.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Playlist deleted')),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Failed to delete playlist')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF282828),
          title: const Text('Rename playlist', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Playlist name',
              hintStyle: TextStyle(color: Color(0xFFB3B3B3)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFFB3B3B3))),
            ),
            FilledButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty) return;
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(dialogCtx);
                try {
                  await ref
                      .read(playlistsRepositoryProvider)
                      .renamePlaylist(playlistId, newName);
                  ref.invalidate(playlistDetailProvider(playlistId));
                  ref.invalidate(userPlaylistsProvider);
                  messenger.showSnackBar(
                    SnackBar(content: Text('Renamed to "$newName"')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Failed to rename playlist')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
