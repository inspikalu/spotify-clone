import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/features/auth/auth_notifier.dart';
import 'package:spotify_clone/features/auth/auth_providers.dart';
import 'package:spotify_clone/features/player/now_playing_screen.dart';
import 'package:spotify_clone/features/player/player_providers.dart';
import 'package:spotify_clone/features/playlists/screens/playlist_detail_screen.dart';
import 'package:spotify_clone/features/playlists/widgets/track_options_sheet.dart';
import 'package:spotify_clone/features/search/models/browse_category.dart';
import 'package:spotify_clone/features/search/models/search_result.dart';
import 'package:spotify_clone/features/search/search_providers.dart';
import 'package:spotify_clone/features/search/widgets/browse_category_card.dart';
import 'package:spotify_clone/features/search/widgets/recent_searches_view.dart';
import 'package:spotify_clone/features/tracks/track.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounceTimer;
  int _selectedFilter = 0; // 0=Top, 1=Songs, 2=Playlists, 3=Artists, 4=Albums

  @override
  void initState() {
    super.initState();
    final initial = ref.read(searchQueryProvider);
    if (initial.isNotEmpty) {
      _searchController.text = initial;
    }
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(searchQueryProvider.notifier).state = _searchController.text.trim();
      }
    });
  }

  void _submitSearch(String query) {
    _debounceTimer?.cancel();
    _searchController.text = query;
    ref.read(searchQueryProvider.notifier).state = query.trim();
    if (query.trim().isNotEmpty) {
      ref.read(recentSearchesProvider.notifier).addQuery(query.trim());
    }
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
    final query = ref.watch(searchQueryProvider);
    final searchAsync = ref.watch(searchResultsProvider(query));
    final recentSearches = ref.watch(recentSearchesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header Row ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  _buildAvatar(context),
                  const SizedBox(width: 12),
                  const Text(
                    'Search',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // ── Search Input Field ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w500),
                  cursorColor: const Color(0xFF1DB954),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      ref.read(recentSearchesProvider.notifier).addQuery(value.trim());
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'What do you want to listen to?',
                    hintStyle: const TextStyle(color: Color(0xFF535353), fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF121212), size: 24),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Color(0xFF121212), size: 20),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // ── Filter Pills (Visible when searching) ───────────────────
            if (query.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: Row(
                  children: [
                    _SearchFilterPill(
                      label: 'Top',
                      selected: _selectedFilter == 0,
                      onTap: () => setState(() => _selectedFilter = 0),
                    ),
                    const SizedBox(width: 8),
                    _SearchFilterPill(
                      label: 'Songs',
                      selected: _selectedFilter == 1,
                      onTap: () => setState(() => _selectedFilter = 1),
                    ),
                    const SizedBox(width: 8),
                    _SearchFilterPill(
                      label: 'Playlists',
                      selected: _selectedFilter == 2,
                      onTap: () => setState(() => _selectedFilter = 2),
                    ),
                    const SizedBox(width: 8),
                    _SearchFilterPill(
                      label: 'Artists',
                      selected: _selectedFilter == 3,
                      onTap: () => setState(() => _selectedFilter = 3),
                    ),
                    const SizedBox(width: 8),
                    _SearchFilterPill(
                      label: 'Albums',
                      selected: _selectedFilter == 4,
                      onTap: () => setState(() => _selectedFilter = 4),
                    ),
                  ],
                ),
              ),

            // ── Main Body: Pre-Search Browse Grid OR Live Results ───────
            Expanded(
              child: query.isEmpty
                  ? _buildPreSearchView(recentSearches)
                  : _buildSearchResultsView(searchAsync, query),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreSearchView(List<String> recentSearches) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        if (recentSearches.isNotEmpty)
          RecentSearchesView(
            queries: recentSearches,
            onSelectQuery: _submitSearch,
            onRemoveQuery: (q) =>
                ref.read(recentSearchesProvider.notifier).removeQuery(q),
            onClearAll: () =>
                ref.read(recentSearchesProvider.notifier).clearAll(),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Text(
            'Browse all',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
            ),
            itemCount: BrowseCategory.defaultCategories.length,
            itemBuilder: (context, index) {
              final cat = BrowseCategory.defaultCategories[index];
              return BrowseCategoryCard(
                category: cat,
                onTap: () => _submitSearch(cat.title),
              );
            },
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSearchResultsView(AsyncValue<SearchResults> searchAsync, String query) {
    return switch (searchAsync) {
      AsyncData(:final value) when value.isEmpty => _buildEmptyResults(query),
      AsyncData(:final value) => _buildResultsList(value),
      AsyncError() => const Center(
          child: Text(
            'Error loading results. Check your connection.',
            style: TextStyle(color: Color(0xFFB3B3B3)),
          ),
        ),
      _ => const Center(
          child: CircularProgressIndicator(color: Color(0xFF1DB954)),
        ),
    };
  }

  Widget _buildEmptyResults(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 72, color: Color(0xFFB3B3B3)),
            const SizedBox(height: 16),
            Text(
              'No results found for "$query"',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please make sure your words are spelled correctly, or use fewer or different keywords.',
              style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(SearchResults results) {
    final showTop = _selectedFilter == 0;
    final showSongs = _selectedFilter == 0 || _selectedFilter == 1;
    final showPlaylists = _selectedFilter == 0 || _selectedFilter == 2;
    final showArtists = _selectedFilter == 0 || _selectedFilter == 3;
    final showAlbums = _selectedFilter == 0 || _selectedFilter == 4;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        // ── Top Result Card (if tracks match) ──────────────────────────
        if (showTop && results.tracks.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Top result',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _TopResultCard(track: results.tracks.first, allTracks: results.tracks),
          ),
          const SizedBox(height: 16),
        ],

        // ── Songs List ────────────────────────────────────────────────
        if (showSongs && results.tracks.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Songs',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...results.tracks.map((track) {
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: track.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: track.coverUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => Container(color: const Color(0xFF282828)),
                        )
                      : Container(color: const Color(0xFF282828), child: const Icon(Icons.music_note, color: Colors.white54)),
                ),
              ),
              title: Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
              ),
              subtitle: Text(
                'Song • ${track.artist}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert, color: Color(0xFFB3B3B3)),
                onPressed: () => showTrackOptionsSheet(context, ref, track),
              ),
              onTap: () {
                ref.read(playbackControllerProvider.notifier).playTrack(track, results.tracks);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
                );
              },
            );
          }),
        ],

        // ── Playlists List ─────────────────────────────────────────────
        if (showPlaylists && results.playlists.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Playlists',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...results.playlists.map((playlist) {
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF282828),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.music_note, color: Colors.white70),
              ),
              title: Text(
                playlist.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
              ),
              subtitle: Text(
                'Playlist • ${playlist.ownerDisplayName ?? 'User'}',
                style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
              ),
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
            );
          }),
        ],

        // ── Artists / Albums ──────────────────────────────────────────
        if (showArtists && results.artists.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Artists',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...results.artists.map((artist) {
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              leading: const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFF282828),
                child: Icon(Icons.person, color: Colors.white70),
              ),
              title: Text(
                artist,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: const Text('Artist', style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 13)),
              onTap: () => _submitSearch(artist),
            );
          }),
        ],

        if (showAlbums && results.albums.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Albums',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...results.albums.map((album) {
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF282828),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.album, color: Colors.white70),
              ),
              title: Text(
                album,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
              ),
              subtitle: const Text('Album', style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 13)),
              onTap: () => _submitSearch(album),
            );
          }),
        ],
      ],
    );
  }
}

class _SearchFilterPill extends StatelessWidget {
  const _SearchFilterPill({
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

class _TopResultCard extends ConsumerWidget {
  const _TopResultCard({required this.track, required this.allTracks});
  final Track track;
  final List<Track> allTracks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 64,
              height: 64,
              child: track.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: track.coverUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Container(color: const Color(0xFF282828)),
                    )
                  : Container(color: const Color(0xFF282828), child: const Icon(Icons.music_note, color: Colors.white54)),
            ),
          ),
          const SizedBox(width: 16),
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
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Song • ${track.artist}',
                  style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 14),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              ref.read(playbackControllerProvider.notifier).playTrack(track, allTracks);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
              );
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1DB954),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 32),
            ),
          ),
        ],
      ),
    );
  }
}