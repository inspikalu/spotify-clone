import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/features/playlists/playlists_providers.dart';
import 'package:spotify_clone/features/tracks/track.dart';

void showAddToPlaylistModal(BuildContext context, WidgetRef ref, Track track) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF282828),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return Consumer(
        builder: (context, ref, _) {
          final playlistsAsync = ref.watch(userPlaylistsProvider);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Add to playlist',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFF3E3E3E), height: 1),
              switch (playlistsAsync) {
                AsyncData(:final value) when value.isEmpty => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No playlists yet. Create one first!',
                        style: TextStyle(color: Color(0xFFB3B3B3)),
                      ),
                    ),
                  ),
                AsyncData(:final value) => Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: value.length,
                      itemBuilder: (context, index) {
                        final playlist = value[index];
                        return ListTile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3E3E3E),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.music_note, color: Colors.white70),
                          ),
                          title: Text(
                            playlist.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${playlist.trackCount} songs',
                            style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
                          ),
                          onTap: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(ctx);
                            try {
                              await ref
                                  .read(playlistsRepositoryProvider)
                                  .addTrackToPlaylist(playlist.id, track.id);
                              ref.invalidate(userPlaylistsProvider);
                              ref.invalidate(playlistDetailProvider(playlist.id));
                              messenger.showSnackBar(
                                SnackBar(content: Text('Added to ${playlist.name}')),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Failed to add track to playlist')),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                AsyncError() => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Failed to load playlists',
                        style: TextStyle(color: Color(0xFFB3B3B3)),
                      ),
                    ),
                  ),
                _ => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              },
            ],
          ),
        ),
      );
    },
  );
    },
  );
}
