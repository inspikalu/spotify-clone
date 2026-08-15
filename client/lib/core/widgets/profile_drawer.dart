import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/features/auth/auth_notifier.dart';
import 'package:spotify_clone/features/auth/auth_providers.dart';

class ProfileDrawer extends ConsumerWidget {
  const ProfileDrawer({super.key});

  Future<void> _logOut(WidgetRef ref, BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(); // Close drawer
    await ref.read(authStateProvider.notifier).logOut();
    messenger.showSnackBar(const SnackBar(content: Text('Signed out')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authStateProvider);
    final email = state is AuthAuthenticated ? state.email : 'User';
    final initial = email.isEmpty ? '?' : email[0].toUpperCase();

    return Drawer(
      backgroundColor: const Color(0xFF121212),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFE88A30),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          email.split('@').first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'View profile',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF282828)),
            ListTile(
              leading: const Icon(Icons.bolt_outlined, color: Colors.white),
              title: const Text(
                "What's new",
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.white),
              title: const Text(
                'Listening history',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: Colors.white),
              title: const Text(
                'Settings and privacy',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
              onTap: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
            const Divider(color: Color(0xFF282828)),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Log out',
                style: TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              onTap: () => _logOut(ref, context),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
