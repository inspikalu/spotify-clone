import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/core/errors.dart';
import 'package:spotify_clone/features/auth/auth_notifier.dart';
import 'package:spotify_clone/features/auth/auth_providers.dart';
import 'package:spotify_clone/features/home/providers/recently_played_provider.dart';
import 'package:spotify_clone/features/home/widgets/horizontal_shelf.dart';
import 'package:spotify_clone/features/player/now_playing_screen.dart';
import 'package:spotify_clone/features/player/player_providers.dart';
import 'package:spotify_clone/features/tracks/track.dart';
import 'package:spotify_clone/features/tracks/tracks_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Widget _buildAvatar(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authStateProvider);
    final email = state is AuthAuthenticated ? state.email : '';
    final initial = email.isEmpty ? '?' : email[0].toUpperCase();
    return GestureDetector(
      onTap: () {
        Scaffold.of(context).openDrawer();
      },
      child: CircleAvatar(
        radius: 17,
        backgroundColor: const Color(0xFFE88A30),
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(tracksProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: switch (tracksAsync) {
        AsyncData(:final value) when value.isEmpty =>
          _EmptyHome(avatarBuilder: () => _buildAvatar(context, ref)),
        AsyncData(:final value) => _HomeContent(
            tracks: value,
            avatarBuilder: () => _buildAvatar(context, ref),
          ),
        AsyncError(:final error) => _HomeError(
            message: apiErrorMessage(error),
            onRetry: () => ref.invalidate(tracksProvider),
            avatarBuilder: () => _buildAvatar(context, ref),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _HomeContent extends ConsumerStatefulWidget {
  const _HomeContent({required this.tracks, required this.avatarBuilder});

  final List<Track> tracks;
  final Widget Function() avatarBuilder;

  @override
  ConsumerState<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<_HomeContent> {
  int _filterIndex = 0; // 0=All, 1=Music, 2=Podcasts

  void _play(Track track, List<Track> queue) {
    ref.read(playbackControllerProvider.notifier).playTrack(track, queue);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
    );
  }

  /// "Made For You" — tracks from artists with ≥2 tracks in the catalog,
  /// de-duplicated by artist and limited to 10. Falls back to catalog order.
  List<Track> _madeForYou(List<Track> all) {
    final artistCounts = <String, int>{};
    for (final t in all) {
      artistCounts[t.artist] = (artistCounts[t.artist] ?? 0) + 1;
    }
    final preferred =
        all.where((t) => (artistCounts[t.artist] ?? 0) >= 2).toList();
    final result = preferred.isNotEmpty ? preferred : all;
    // deduplicate by artist — keep first occurrence
    final seen = <String>{};
    return result.where((t) => seen.add(t.artist)).take(10).toList();
  }

  /// "Popular releases" — sort by durationMs descending as a proxy for
  /// "album track" (singles tend to be shorter). Take up to 10.
  List<Track> _popularReleases(List<Track> all) {
    final sorted = [...all]
      ..sort((a, b) =>
          (b.durationMs ?? 0).compareTo(a.durationMs ?? 0));
    return sorted.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tracks = widget.tracks;
    final gridItems = tracks.take(6).toList();

    final recentAsync = ref.watch(recentlyPlayedTracksProvider);
    final recentTracks =
        recentAsync.whenOrNull(data: (list) => list) ?? [];

    final madeForYouTracks = _madeForYou(tracks);
    final popularTracks = _popularReleases(tracks);

    final isPodcasts = _filterIndex == 2;
    final isAll = _filterIndex == 0;
    final isMusic = _filterIndex == 1;

    return CustomScrollView(
      slivers: [
        // ─── Sticky header: Avatar + filter pills ───
        SliverAppBar(
          backgroundColor: const Color(0xFF000000),
          pinned: true,
          expandedHeight: 0,
          toolbarHeight: 56,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Center(child: widget.avatarBuilder()),
          ),
          leadingWidth: 50,
          titleSpacing: 10,
          title: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterPill(
                  label: 'All',
                  selected: _filterIndex == 0,
                  onTap: () => setState(() => _filterIndex = 0),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'Music',
                  selected: _filterIndex == 1,
                  onTap: () => setState(() => _filterIndex = 1),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'Podcasts',
                  selected: _filterIndex == 2,
                  onTap: () => setState(() => _filterIndex = 2),
                ),
              ],
            ),
          ),
        ),

        // ─── Podcasts filter: empty state ───
        if (isPodcasts)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.podcasts_rounded,
                    size: 72,
                    color: Color(0xFFB3B3B3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No podcasts yet',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: const Color(0xFFB3B3B3)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Podcast streaming is coming soon',
                    style: TextStyle(color: Color(0xFF6E6E6E), fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

        // ─── Quick-access 2-col grid (All + Music only) ───
        if (!isPodcasts && gridItems.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 3.2,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = gridItems[index];
                  return _QuickAccessTile(
                    track: track,
                    onTap: () => _play(track, tracks),
                  );
                },
                childCount: gridItems.length,
              ),
            ),
          ),
        ],

        // ─── Recently Played shelf ───
        if ((isAll || isMusic) && recentTracks.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          SliverToBoxAdapter(
            child: HorizontalShelf(
              title: 'Recently played',
              tracks: recentTracks,
              onTrackTap: (track) => _play(track, recentTracks),
            ),
          ),
        ],

        // ─── Made For You shelf ───
        if ((isAll || isMusic) && madeForYouTracks.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          SliverToBoxAdapter(
            child: HorizontalShelf(
              title: 'Made for you',
              subtitle: 'Based on your library',
              tracks: madeForYouTracks,
              onTrackTap: (track) => _play(track, madeForYouTracks),
            ),
          ),
        ],

        // ─── Your tracks / Popular releases shelf ───
        if (!isPodcasts && popularTracks.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          SliverToBoxAdapter(
            child: HorizontalShelf(
              title: isMusic ? 'Popular releases' : 'Your tracks',
              tracks: popularTracks,
              onTrackTap: (track) => _play(track, popularTracks),
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1DB954) : const Color(0xFF282828),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _QuickAccessTile extends ConsumerWidget {
  const _QuickAccessTile({required this.track, required this.onTap});

  final Track track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverUrl = track.coverUrl;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(6),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: double.infinity,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  track.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome({required this.avatarBuilder});

  final Widget Function() avatarBuilder;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: const Color(0xFF000000),
          pinned: true,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Center(child: avatarBuilder()),
          ),
          leadingWidth: 50,
        ),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.library_music,
                  size: 72,
                  color: Color(0xFFB3B3B3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No tracks in your library yet',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: const Color(0xFFB3B3B3)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({
    required this.message,
    required this.onRetry,
    required this.avatarBuilder,
  });

  final String message;
  final VoidCallback onRetry;
  final Widget Function() avatarBuilder;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: const Color(0xFF000000),
          pinned: true,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Center(child: avatarBuilder()),
          ),
          leadingWidth: 50,
        ),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 72, color: Color(0xFFB3B3B3)),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(color: Color(0xFFB3B3B3)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
