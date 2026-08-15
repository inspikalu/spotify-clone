import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:spotify_clone/features/search/models/browse_category.dart';

class BrowseCategoryCard extends StatelessWidget {
  const BrowseCategoryCard({
    super.key,
    required this.category,
    this.onTap,
  });

  final BrowseCategory category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Material(
        color: category.color,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  category.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Positioned(
                bottom: -10,
                right: -10,
                child: Transform.rotate(
                  angle: math.pi / 8,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(2, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      category.icon,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: 36,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
