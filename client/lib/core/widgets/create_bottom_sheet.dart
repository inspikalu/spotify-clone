import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/features/playlists/playlists_providers.dart';

void showCreateBottomSheet(BuildContext context, [WidgetRef? ref]) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF282828),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _CreateOptionTile(
                  icon: Icons.music_note,
                  title: 'Playlist',
                  subtitle: 'Create a playlist with songs or episodes',
                  onTap: () {
                    Navigator.pop(ctx);
                    _promptCreatePlaylist(context, ref);
                  },
                ),
                _CreateOptionTile(
                  icon: Icons.people_outline,
                  title: 'Collaborative playlist',
                  subtitle: 'Create a playlist together with friends',
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Collaborative playlist coming soon')),
                    );
                  },
                ),
                _CreateOptionTile(
                  icon: Icons.tune,
                  title: 'Mixed playlist',
                  badgeText: 'Beta',
                  subtitle: 'Mix songs with smooth transitions',
                  onTap: () => Navigator.pop(ctx),
                ),
                _CreateOptionTile(
                  icon: Icons.bubble_chart_outlined,
                  title: 'Blend',
                  subtitle: "Combine your friends' tastes into a playlist",
                  onTap: () => Navigator.pop(ctx),
                ),
                _CreateOptionTile(
                  icon: Icons.auto_awesome,
                  title: 'AI Playlist',
                  badgeText: 'Beta',
                  subtitle: 'Turn your ideas into playlists with AI',
                  onTap: () => Navigator.pop(ctx),
                ),
                _CreateOptionTile(
                  icon: Icons.speaker_group_outlined,
                  title: 'Jam',
                  subtitle: 'Listen together from anywhere',
                  onTap: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void _promptCreatePlaylist(BuildContext context, WidgetRef? ref) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (dialogCtx) {
      return AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text(
          'Give your playlist a name',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'My playlist',
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
              final name = controller.text.trim();
              if (name.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogCtx);
              if (ref != null) {
                try {
                  await ref.read(playlistsRepositoryProvider).createPlaylist(name);
                  ref.invalidate(userPlaylistsProvider);
                  messenger.showSnackBar(
                    SnackBar(content: Text('Created "$name"')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Failed to create playlist')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      );
    },
  );
}

class _CreateOptionTile extends StatelessWidget {
  const _CreateOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeText,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? badgeText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFF3E3E3E),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      title: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          if (badgeText != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badgeText!,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
      ),
      onTap: onTap,
    );
  }
}
