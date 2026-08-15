import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:spotify_clone/features/tracks/track.dart';

/// A horizontal scrolling shelf of track cards.
///
/// Each card shows cover art (160×160), track title, and artist/album subtitle.
/// Tapping a card calls [onTrackTap] with the selected [Track].
class HorizontalShelf extends StatelessWidget {
  const HorizontalShelf({
    super.key,
    required this.title,
    required this.tracks,
    required this.onTrackTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Track> tracks;
  final void Function(Track track) onTrackTap;

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: Color(0xFFB3B3B3),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tracks.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final track = tracks[index];
              return _ShelfCard(
                track: track,
                onTap: () => onTrackTap(track),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ShelfCard extends StatelessWidget {
  const _ShelfCard({required this.track, required this.onTap});

  final Track track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final coverUrl = track.coverUrl;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover art 140×140
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 140,
                height: 140,
                child: coverUrl == null
                    ? Container(
                        color: const Color(0xFF282828),
                        child: const Icon(
                          Icons.music_note,
                          size: 52,
                          color: Colors.white38,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: coverUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            Container(color: const Color(0xFF282828)),
                        errorWidget: (_, _, _) => Container(
                          color: const Color(0xFF282828),
                          child: const Icon(
                            Icons.music_note,
                            size: 52,
                            color: Colors.white38,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            // Subtitle: artist (+ album if present)
            Text(
              track.album != null && track.album!.isNotEmpty
                  ? '${track.artist} · ${track.album}'
                  : track.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
