import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/features/auth/auth_notifier.dart';
import 'package:spotify_clone/features/auth/auth_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _logOut(WidgetRef ref, BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(authStateProvider.notifier).logOut();
    messenger.showSnackBar(const SnackBar(content: Text('Signed out')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authStateProvider);
    final email = state is AuthAuthenticated ? state.email : '';
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 72),
            const SizedBox(height: 16),
            Text(
              'Signed in as $email',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => _logOut(ref, context),
              child: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}