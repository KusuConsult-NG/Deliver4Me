import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deliver4me_mobile/providers/auth_provider.dart';
import 'package:deliver4me_mobile/models/user_model.dart';
import 'package:deliver4me_mobile/screens/sender/sender_home_screen.dart';
import 'package:deliver4me_mobile/screens/rider/available_jobs_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          // This shouldn't happen if auth guard is working, but just in case
          return const Scaffold(body: Center(child: Text('Please log in')));
        }

        if (user.role == UserRole.rider) {
          return const AvailableJobsScreen();
        } else {
          return const SenderHomeScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}
