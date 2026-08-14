import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/core/errors.dart';
import 'package:spotify_clone/features/auth/auth_notifier.dart';
import 'package:spotify_clone/features/auth/auth_providers.dart';
import 'package:spotify_clone/features/player/now_playing_screen.dart';
import 'package:spotify_clone/features/player/player_providers.dart';
import 'package:spotify_clone/features/tracks/track.dart';
import 'package:spotify_clone/features/tracks/tracks_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _logOut(WidgetRef ref, BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(authStateProvider.notifier).logOut();
    messenger.showSnackBar(const SnackBar(content: Text('Signed out')));
  }

  Widget _buildAvatar(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authStateProvider);
    final email = state is AuthAuthenticated ? state.email : '';
    final initial = email.isEmpty ? '?' : email[0].toUpperCase();
    return PopupMenuButton<String>(
      tooltip: 'Account',
      onSelected: (value) {
        if (value == 'logout') {
          _logOut(ref, context);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'logout', child: Text('Log out')),
      ],
      child: CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFF282828),
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(tracksProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: _buildAvatar(context, ref),
        ),
        leadingWidth: 56,
        actions: const [],
      ),
      body: switch (tracksAsync) {
        AsyncData(:final value) when value.isEmpty =>
          const _EmptyHome(),
        AsyncData(:final value) => _Shelf(tracks: value),
        AsyncError(:final error) => _HomeError(
            message: apiErrorMessage(error),
            onRetry: () => ref.invalidate(tracksProvider),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Shelf extends ConsumerWidget {
  const _Shelf({required this.tracks});

  final List<Track> tracks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'All uploaded tracks',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tracks.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final track = tracks[index];
              return _ShelfCard(track: track, queue: tracks);
            },
          ),
        ),
      ],
    );
  }
}

class _ShelfCard extends ConsumerWidget {
  const _ShelfCard({required this.track, required this.queue});

  final Track track;
  final List<Track> queue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 160,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          ref.read(playbackControllerProvider.notifier).playTrack(track, queue);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: track.coverUrl == null
                  ? const _CoverPlaceholder(size: 160)
                  : CachedNetworkImage(
                      imageUrl: track.coverUrl!,
                      width: 160,
                      height: 160,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          const _CoverPlaceholder(size: 160),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              track.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFF282828),
      child: const Center(
        child: Icon(Icons.music_note, color: Color(0xFFB3B3B3), size: 40),
      ),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.library_music, size: 72, color: Color(0xFFB3B3B3)),
          const SizedBox(height: 16),
          Text(
            'No tracks yet — upload one from the Library tab',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: const Color(0xFFB3B3B3)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}
