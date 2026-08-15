import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotify_clone/core/color_extractor.dart';

void main() {
  group('ambientColorFromSeed', () {
    test('returns a non-transparent color for any non-empty seed', () {
      final color = ambientColorFromSeed('some-track-id');
      expect(color.a, equals(1.0));
    });

    test('returns fallback dark color for empty seed', () {
      final color = ambientColorFromSeed('');
      expect(color, equals(const Color(0xFF1E1E1E)));
    });

    test('is deterministic — same seed always returns same color', () {
      const seed = 'track-abc-123';
      final c1 = ambientColorFromSeed(seed);
      final c2 = ambientColorFromSeed(seed);
      expect(c1, equals(c2));
    });

    test('different seeds produce different colors', () {
      final c1 = ambientColorFromSeed('seed-A');
      final c2 = ambientColorFromSeed('seed-B');
      // They could theoretically collide, but djb2 makes this effectively impossible for short strings
      expect(c1, isNot(equals(c2)));
    });

    test('color has sufficient darkness — lightness <= 0.40 for dark-mode use', () {
      const seeds = ['track-1', 'track-2', 'track-xyz', 'abc', '12345'];
      for (final seed in seeds) {
        final color = ambientColorFromSeed(seed);
        final hsl = HSLColor.fromColor(color);
        expect(
          hsl.lightness,
          lessThanOrEqualTo(0.40),
          reason: 'Seed "$seed" produced a color that is too light for dark mode',
        );
      }
    });
  });

  group('ambientGradient', () {
    test('returns a LinearGradient with 3 color stops', () {
      final gradient = ambientGradient('track-id');
      expect(gradient, isA<LinearGradient>());
      expect(gradient.colors.length, 3);
      expect(gradient.stops, [0.0, 0.5, 1.0]);
    });

    test('gradient end color is near-black', () {
      final gradient = ambientGradient('any-seed');
      final endColor = gradient.colors.last;
      final hsl = HSLColor.fromColor(endColor);
      expect(hsl.lightness, lessThan(0.05));
    });
  });
}
