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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final resetToken = extractResetToken();
  runApp(
    ProviderScope(
      overrides: [
        if (resetToken != null)
          resetTokenProvider.overrideWith((ref) => resetToken),
      ],
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