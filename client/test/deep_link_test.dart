import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotify_clone/core/deep_link.dart';

TestPlatformDispatcher get testDispatcher {
  return WidgetsBinding.instance.platformDispatcher as TestPlatformDispatcher;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('extracts the reset token from a valid deep link', () {
    testDispatcher.defaultRouteNameTestValue =
        'spotifyclone://auth/reset?token=abc123';

    expect(extractResetToken(), 'abc123');
  });

  test('returns null for links that are not password-reset deep links', () {
    testDispatcher.defaultRouteNameTestValue =
        'https://example.com/somewhere';

    expect(extractResetToken(), isNull);
  });

  test('returns null when the reset token parameter is missing', () {
    testDispatcher.defaultRouteNameTestValue = 'spotifyclone://auth/reset';

    expect(extractResetToken(), isNull);
  });
}