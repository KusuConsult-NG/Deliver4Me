import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:deliver4me_mobile/services/auth_service.dart';
import 'package:deliver4me_mobile/models/user_model.dart';
import 'package:deliver4me_mobile/services/user_service.dart';

// Service providers
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final userServiceProvider = Provider<UserService>((ref) => UserService());

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Current user provider
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(userServiceProvider).streamUser(user.uid);
    },
    loading: () => Stream.value(null),
    error: (e, st) {
      // ignore: avoid_print
      print('AuthProvider Error: $e');
      // ignore: avoid_print
      print(st);
      return Stream.value(null);
    },
  );
});

// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value != null;
});
