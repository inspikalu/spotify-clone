import 'package:flutter_test/flutter_test.dart';
import 'package:spotify_clone/core/deep_link.dart';

void main() {
  test('extracts the reset token from a valid deep link', () {
    expect(
      resetTokenFromUri(Uri.parse('spotifyclone://auth/reset?token=abc123')),
      'abc123',
    );
  });

  test('returns null for links that are not password-reset deep links', () {
    expect(
      resetTokenFromUri(Uri.parse('https://example.com/somewhere')),
      isNull,
    );
  });

  test('returns null when the reset token parameter is missing', () {
    expect(
      resetTokenFromUri(Uri.parse('spotifyclone://auth/reset')),
      isNull,
    );
  });
}