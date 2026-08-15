import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/core/errors.dart';
import 'package:spotify_clone/core/widgets/create_bottom_sheet.dart';
import 'package:spotify_clone/features/auth/auth_notifier.dart';
import 'package:spotify_clone/features/auth/auth_providers.dart';
import 'package:spotify_clone/features/player/player_providers.dart';
import 'package:spotify_clone/features/tracks/track.dart';
import 'package:spotify_clone/features/tracks/tracks_providers.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  bool _sortAz = false;
  int _filterIndex = 0; // 0=Playlists, 1=Podcasts, 2=Albums, 3=Artists, 4=Downloaded

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(tracksProvider);
    await ref.read(tracksProvider.future);
  }

  List<Track> _sorted(List<Track> tracks) {
    if (!_sortAz) {
      return tracks;
    }
    final sorted = [...tracks];
    sorted.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return sorted;
  }

  Widget _buildAvatar(BuildContext context) {
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
  Widget build(BuildContext context) {
    final tracksAsync = ref.watch(tracksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(child: _buildAvatar(context)),
        ),
        leadingWidth: 50,
        title: const Text(
          'Your Library',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showCreateBottomSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter pills (Playlists, Podcasts, Albums, Artists, Downloaded)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _LibraryPill(
                  label: 'Playlists',
                  selected: _filterIndex == 0,
                  onTap: () => setState(() => _filterIndex = 0),
                ),
                const SizedBox(width: 8),
                _LibraryPill(
                  label: 'Podcasts',
                  selected: _filterIndex == 1,
                  onTap: () => setState(() => _filterIndex = 1),
                ),
                const SizedBox(width: 8),
                _LibraryPill(
                  label: 'Albums',
                  selected: _filterIndex == 2,
                  onTap: () => setState(() => _filterIndex = 2),
                ),
                const SizedBox(width: 8),
                _LibraryPill(
                  label: 'Artists',
                  selected: _filterIndex == 3,
                  onTap: () => setState(() => _filterIndex = 3),
                ),
                const SizedBox(width: 8),
                _LibraryPill(
                  label: 'Downloaded',
                  selected: _filterIndex == 4,
                  onTap: () => setState(() => _filterIndex = 4),
                ),
              ],
            ),
          ),

          // Sort row: "Recents" / "A-Z" toggle + grid icon
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => setState(() => _sortAz = !_sortAz),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.swap_vert, size: 18, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          _sortAz ? 'A\u2013Z' : 'Recents',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Icon(Icons.grid_view_outlined, size: 18, color: Color(0xFFB3B3B3)),
              ],
            ),
          ),

          Expanded(
            child: switch (tracksAsync) {
              AsyncData(:final value) when value.isEmpty =>
                const _EmptyLibrary(),
              AsyncData(:final value) => RefreshIndicator(
                  onRefresh: () => _refresh(ref),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      // Liked Songs playlist tile
                      _SpecialLibraryTile(
                        icon: Icons.favorite,
                        gradientColors: const [Color(0xFF450af5), Color(0xFF8e8ee5)],
                        title: 'Liked Songs',
                        subtitle: 'Playlist \u2022 ${value.length} songs',
                        onTap: () {},
                      ),
                      // Your Episodes tile
                      _SpecialLibraryTile(
                        icon: Icons.bookmark,
                        gradientColors: const [Color(0xFF006450), Color(0xFF056952)],
                        title: 'Your Episodes',
                        subtitle: 'Playlist \u2022 Saved & downloaded episodes',
                        onTap: () {},
                      ),
                      // Real tracks list
                      ..._sorted(value).map((track) {
                        return ListTile(
                          onTap: () => ref
                              .read(playbackControllerProvider.notifier)
                              .playTrack(track, value),
                          leading: _TrackCover(track: track),
                          title: Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            track.album == null
                                ? 'Single \u2022 ${track.artist}'
                                : 'Album \u2022 ${track.artist}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFB3B3B3),
                              fontSize: 13,
                            ),
                          ),
                          trailing: track.durationLabel.isEmpty
                              ? null
                              : Text(
                                  track.durationLabel,
                                  style: const TextStyle(
                                    color: Color(0xFFB3B3B3),
                                    fontSize: 13,
                                  ),
                                ),
                        );
                      }),
                    ],
                  ),
                ),
              AsyncError(:final error) => _LibraryError(
                  message: apiErrorMessage(error),
                  onRetry: () => ref.invalidate(tracksProvider),
                ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _LibraryPill extends StatelessWidget {
  const _LibraryPill({
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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

class _SpecialLibraryTile extends StatelessWidget {
  const _SpecialLibraryTile({
    required this.icon,
    required this.gradientColors,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final List<Color> gradientColors;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      subtitle: Row(
        children: [
          const Icon(Icons.push_pin, size: 13, color: Color(0xFF1DB954)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackCover extends StatelessWidget {
  const _TrackCover({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final coverUrl = track.coverUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 56,
        height: 56,
        child: coverUrl == null
            ? const _CoverPlaceholder()
            : CachedNetworkImage(
                imageUrl: coverUrl,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const _CoverPlaceholder(),
              ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      color: const Color(0xFF282828),
      child: const Center(
        child: Icon(Icons.music_note, color: Color(0xFFB3B3B3), size: 24),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_music,
            size: 72,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No tracks yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Your saved music will appear here',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LibraryError extends StatelessWidget {
  const _LibraryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 72,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
