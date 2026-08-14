import 'package:flutter/material.dart';
import 'package:spotify_clone/features/home/home_screen.dart';
import 'package:spotify_clone/features/player/mini_player.dart';
import 'package:spotify_clone/features/search/search_screen.dart';
import 'package:spotify_clone/features/tracks/library_screen.dart';

class NavShell extends StatefulWidget {
  const NavShell({super.key});

  @override
  State<NavShell> createState() => _NavShellState();
}

class _NavShellState extends State<NavShell> {
  int _index = 2;

  @override
  Widget build(BuildContext context) {
    final body = switch (_index) {
      0 => const HomeScreen(),
      1 => const SearchScreen(),
      _ => const LibraryScreen(),
    };
    return Scaffold(
      body: body,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music),
                label: 'Library',
              ),
            ],
          ),
        ],
      ),
    );
  }
}