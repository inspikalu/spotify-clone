import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/core/errors.dart';
import 'package:spotify_clone/core/widgets/create_bottom_sheet.dart';
import 'package:spotify_clone/features/auth/auth_notifier.dart';
import 'package:spotify_clone/features/auth/auth_providers.dart';
import 'package:spotify_clone/features/playlists/models/playlist.dart';
import 'package:spotify_clone/features/playlists/playlists_providers.dart';
import 'package:spotify_clone/features/playlists/screens/liked_songs_screen.dart';
import 'package:spotify_clone/features/playlists/screens/playlist_detail_screen.dart';
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
    ref.invalidate(userPlaylistsProvider);
    await Future.wait([
      ref.read(tracksProvider.future),
      ref.read(userPlaylistsProvider.future),
    ]);
  }

  List<Playlist> _sortedPlaylists(List<Playlist> playlists) {
    if (!_sortAz) return playlists;
    final sorted = [...playlists];
    sorted.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
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
    final playlistsAsync = ref.watch(userPlaylistsProvider);
    final likedCount = ref.watch(likedTracksProvider).value?.length ?? 0;

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
            child: RefreshIndicator(
              onRefresh: () => _refresh(ref),
              child: switch (_filterIndex) {
                // ── Filter 0: Playlists ────────────────────────────────────
                0 => switch (playlistsAsync) {
                    AsyncData(:final value) => ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          // Pinned Liked Songs playlist tile
                          _SpecialLibraryTile(
                            icon: Icons.favorite,
                            gradientColors: const [Color(0xFF450af5), Color(0xFF8e8ee5)],
                            title: 'Liked Songs',
                            subtitle: 'Playlist \u2022 $likedCount songs',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const LikedSongsScreen()),
                              );
                            },
                          ),
                          // Pinned Your Episodes tile
                          _SpecialLibraryTile(
                            icon: Icons.bookmark,
                            gradientColors: const [Color(0xFF006450), Color(0xFF056952)],
                            title: 'Your Episodes',
                            subtitle: 'Playlist \u2022 Saved & downloaded episodes',
                            onTap: () {},
                          ),

                          // User Created Playlists
                          ..._sortedPlaylists(value).map((playlist) {
                            return ListTile(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PlaylistDetailScreen(
                                      playlistId: playlist.id,
                                      initialName: playlist.name,
                                    ),
                                  ),
                                );
                              },
                              leading: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF282828),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.music_note, color: Colors.white70, size: 28),
                              ),
                              title: Text(
                                playlist.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text(
                                'Playlist \u2022 ${playlist.ownerDisplayName ?? 'You'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
                              ),
                            );
                          }),
                        ],
                      ),
                    AsyncError(:final error) => _LibraryError(
                        message: apiErrorMessage(error),
                        onRetry: () => ref.invalidate(userPlaylistsProvider),
                      ),
                    _ => const Center(child: CircularProgressIndicator()),
                  },

                // ── Filter 1: Podcasts ─────────────────────────────────────
                1 => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _SpecialLibraryTile(
                        icon: Icons.bookmark,
                        gradientColors: const [Color(0xFF006450), Color(0xFF056952)],
                        title: 'Your Episodes',
                        subtitle: 'Saved & downloaded episodes',
                        onTap: () {},
                      ),
                    ],
                  ),

                // ── Filter 2: Albums (saved albums only) ───────────────────
                2 => const _EmptySection(
                    icon: Icons.album_outlined,
                    title: 'No saved albums yet',
                    subtitle: 'Albums you save with the + button will appear here',
                  ),

                // ── Filter 3: Artists (followed artists only) ──────────────
                3 => const _EmptySection(
                    icon: Icons.person_outline,
                    title: 'No followed artists yet',
                    subtitle: 'Artists you follow will appear here',
                  ),

                // ── Filter 4: Downloaded ───────────────────────────────────
                _ => const _EmptySection(
                    icon: Icons.download_done_rounded,
                    title: 'No downloads yet',
                    subtitle: 'Downloaded music and podcasts will appear here',
                  ),
              },
            ),
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

class _EmptySection extends StatelessWidget {
  const _EmptySection({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: const Color(0xFFB3B3B3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFFB3B3B3),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
