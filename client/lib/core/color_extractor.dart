import 'package:flutter/material.dart';

/// Derives a stable, aesthetically dark-mode-friendly ambient [Color] from an
/// arbitrary string (typically a track ID or cover URL).
///
/// Algorithm:
///   1. Compute a djb2 hash of [seed].
///   2. Map the hash to a hue in [0, 360).
///   3. Return an HSL color with fixed saturation 55% and lightness 28%,
///      producing a rich, muted tone that pairs well with white text on a dark
///      background.
///
/// Pure Dart — zero external dependencies, works in unit tests without a
/// render surface.
Color ambientColorFromSeed(String seed) {
  if (seed.isEmpty) return const Color(0xFF1E1E1E);

  // djb2 hash
  var hash = 5381;
  for (final codeUnit in seed.codeUnits) {
    hash = ((hash << 5) + hash) ^ codeUnit;
    hash &= 0x7FFFFFFF; // keep positive 31-bit
  }

  final hue = (hash % 360).toDouble();
  return HSLColor.fromAHSL(1.0, hue, 0.55, 0.28).toColor();
}

/// Returns a [LinearGradient] suitable for a hero header or Now-Playing
/// background, going from [ambientColorFromSeed] at the top to near-black
/// at the bottom.
LinearGradient ambientGradient(String seed) {
  final ambient = ambientColorFromSeed(seed);
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      ambient,
      Color.lerp(ambient, Colors.black, 0.6)!,
      const Color(0xFF080808),
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}
