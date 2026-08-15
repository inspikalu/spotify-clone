import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/features/playlists/playlists_providers.dart';
import 'package:spotify_clone/features/playlists/widgets/add_to_playlist_modal.dart';
import 'package:spotify_clone/features/tracks/track.dart';

void showTrackOptionsSheet(BuildContext context, WidgetRef ref, Track track) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF282828),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final isLiked = ref.watch(likedTracksProvider.notifier).isLiked(track.id);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E3E3E),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white70),
                  ),
                  const SizedBox(width: 12),
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
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          track.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF3E3E3E), height: 1),
            ListTile(
              leading: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? const Color(0xFF1DB954) : Colors.white,
              ),
              title: Text(
                isLiked ? 'Liked' : 'Like',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(likedTracksProvider.notifier).toggleLike(track);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add, color: Colors.white),
              title: const Text('Add to playlist', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                showAddToPlaylistModal(context, ref, track);
              },
            ),
          ],
        ),
      );
    },
  );
}
