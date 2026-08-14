import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/core/deep_link.dart';
import 'package:spotify_clone/core/theme.dart';
import 'package:spotify_clone/features/auth/auth_notifier.dart';
import 'package:spotify_clone/features/auth/auth_providers.dart';
import 'package:spotify_clone/features/auth/screens/home_screen.dart';
import 'package:spotify_clone/features/auth/screens/reset_password_screen.dart';
import 'package:spotify_clone/features/auth/screens/sign_in_screen.dart';
import 'package:spotify_clone/features/auth/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appLinks = AppLinks();
  Uri? initialLink;
  try {
    initialLink = await appLinks.getInitialLink();
  } on Exception {
    initialLink = null;
  }
  final initialToken = resetTokenFromUri(initialLink);

  final container = ProviderContainer(
    overrides: [
      if (initialToken != null)
        resetTokenProvider.overrideWith((ref) => initialToken),
    ],
  );

  appLinks.uriLinkStream.listen((uri) {
    final token = resetTokenFromUri(uri);
    if (token != null) {
      container.read(resetTokenProvider.notifier).state = token;
    }
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SpotifyCloneApp(),
    ),
  );
}

class SpotifyCloneApp extends StatelessWidget {
  const SpotifyCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppTheme.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resetToken = ref.watch(resetTokenProvider);
    if (resetToken != null) {
      return ResetPasswordScreen(token: resetToken);
    }
    return switch (ref.watch(authStateProvider)) {
      AuthUnknown() => const SplashScreen(),
      AuthUnauthenticated() => const SignInScreen(),
      AuthAuthenticated() => const HomeScreen(),
    };
  }
}