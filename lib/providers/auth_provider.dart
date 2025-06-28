import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Make sure this is imported
import '../services/firebase_service.dart';

// Provides an instance of your AuthService class
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Provides a stream of Firebase User? (null if signed out)
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authState;
});

