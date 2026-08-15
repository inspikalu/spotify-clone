import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/features/player/player_providers.dart';
import 'package:spotify_clone/features/playlists/playlists_providers.dart';
import 'package:spotify_clone/features/playlists/widgets/track_options_sheet.dart';
import 'package:spotify_clone/features/tracks/track.dart';

class LikedSongsScreen extends ConsumerStatefulWidget {
  const LikedSongsScreen({super.key});

  @override
  ConsumerState<LikedSongsScreen> createState() => _LikedSongsScreenState();
}

class _LikedSongsScreenState extends ConsumerState<LikedSongsScreen> {
  final _scrollController = ScrollController();
  bool _showTopBar = false;

  static const _topGradient = Color(0xFF1a0a4a);
  static const _bottomGradient = Color(0xFF0d0d0d);
  static const _purple = Color(0xFF450af5);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final show = _scrollController.offset > 140;
      if (show != _showTopBar) setState(() => _showTopBar = show);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final likedAsync = ref.watch(likedTracksProvider);
    final tracks = likedAsync.value ?? [];

    return Scaffold(
      backgroundColor: _bottomGradient,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ── Gradient hero header ──────────────────────────────────
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: _topGradient,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                // Collapsing title shown when scrolled up
                title: AnimatedOpacity(
                  opacity: _showTopBar ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: const Text(
                    'Liked Songs',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_purple, _topGradient],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search + Sort row (visible in expanded state)
                            _SearchSortRow(trackCount: tracks.length),
                            const SizedBox(height: 20),
                            const Text(
                              'Liked Songs',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${tracks.length} songs',
                              style: const TextStyle(
                                color: Color(0xFFB3B3B3),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Play controls row ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: _bottomGradient,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      // Download button
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1DB954),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.download_rounded, color: Colors.black, size: 20),
                      ),
                      const Spacer(),
                      // Shuffle
                      IconButton(
                        icon: const Icon(Icons.shuffle_rounded, color: Color(0xFFB3B3B3), size: 26),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                      // Play
                      GestureDetector(
                        onTap: tracks.isEmpty
                            ? null
                            : () => ref
                                .read(playbackControllerProvider.notifier)
                                .playTrack(tracks.first, tracks),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1DB954),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 30),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Genre filter pills ────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: _bottomGradient,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        _GenrePill(label: 'Dance'),
                        _GenrePill(label: 'Afrobeats'),
                        _GenrePill(label: 'Rap'),
                        _GenrePill(label: 'Chill'),
                        _GenrePill(label: 'Pop'),
                        _GenrePill(label: 'New'),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Add to playlist tile ──────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: _bottomGradient,
                  child: ListTile(
                    leading: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF282828),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 28),
                    ),
                    title: const Text(
                      'Add to this playlist',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ),
              ),

              // ── Track list ────────────────────────────────────────────
              if (tracks.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.favorite_border, color: Color(0xFFB3B3B3), size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          'Songs you like will appear here',
                          style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final track = tracks[index];
                      return _LikedTrackTile(track: track, allTracks: tracks);
                    },
                    childCount: tracks.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // ── Sticky search + sort bar (appears when scrolled) ─────────
          AnimatedSlide(
            offset: _showTopBar ? Offset.zero : const Offset(0, -1),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: _showTopBar ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 56, 16, 8),
                  child: _SearchSortRow(trackCount: tracks.length),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchSortRow extends StatelessWidget {
  const _SearchSortRow({required this.trackCount});
  final int trackCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.white70, size: 18),
                SizedBox(width: 8),
                Text(
                  'Find in Liked Songs',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Center(
            child: Text(
              'Sort',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GenrePill extends StatelessWidget {
  const _GenrePill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _LikedTrackTile extends ConsumerWidget {
  const _LikedTrackTile({required this.track, required this.allTracks});
  final Track track;
  final List<Track> allTracks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: () => ref.read(playbackControllerProvider.notifier).playTrack(track, allTracks),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 52,
          height: 52,
          child: track.coverUrl != null
              ? CachedNetworkImage(
                  imageUrl: track.coverUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const _CoverPlaceholder(),
                )
              : const _CoverPlaceholder(),
        ),
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert, color: Color(0xFFB3B3B3)),
        onPressed: () => showTrackOptionsSheet(context, ref, track),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF282828),
      child: const Icon(Icons.music_note, color: Color(0xFFB3B3B3), size: 22),
    );
  }
}
