import 'package:flutter/material.dart';

class BrowseCategory {
  const BrowseCategory({
    required this.id,
    required this.title,
    required this.color,
    this.icon = Icons.music_note,
  });

  final String id;
  final String title;
  final Color color;
  final IconData icon;

  static const defaultCategories = [
    BrowseCategory(
      id: 'music',
      title: 'Music',
      color: Color(0xFFDC148C),
      icon: Icons.headphones,
    ),
    BrowseCategory(
      id: 'podcasts',
      title: 'Podcasts',
      color: Color(0xFF006450),
      icon: Icons.podcasts,
    ),
    BrowseCategory(
      id: 'afrobeats',
      title: 'Afrobeats',
      color: Color(0xFFE91429),
      icon: Icons.album,
    ),
    BrowseCategory(
      id: 'hiphop',
      title: 'Hip-Hop',
      color: Color(0xFFBC5900),
      icon: Icons.speaker,
    ),
    BrowseCategory(
      id: 'pop',
      title: 'Pop',
      color: Color(0xFF1E3264),
      icon: Icons.auto_awesome,
    ),
    BrowseCategory(
      id: 'dance',
      title: 'Dance / Electronic',
      color: Color(0xFFD84000),
      icon: Icons.graphic_eq,
    ),
    BrowseCategory(
      id: 'rnb',
      title: 'R&B',
      color: Color(0xFF8D67AB),
      icon: Icons.favorite,
    ),
    BrowseCategory(
      id: 'rock',
      title: 'Rock',
      color: Color(0xFFE61E32),
      icon: Icons.electric_bolt,
    ),
    BrowseCategory(
      id: 'chill',
      title: 'Chill',
      color: Color(0xFF477D95),
      icon: Icons.spa,
    ),
    BrowseCategory(
      id: 'new',
      title: 'New Releases',
      color: Color(0xFFE8115B),
      icon: Icons.new_releases,
    ),
    BrowseCategory(
      id: 'charts',
      title: 'Charts',
      color: Color(0xFF8C1932),
      icon: Icons.trending_up,
    ),
    BrowseCategory(
      id: 'live',
      title: 'Live Events',
      color: Color(0xFF7358FF),
      icon: Icons.confirmation_number,
    ),
  ];
}
