import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Make sure this is imported
import '../services/firebase_service.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';

// Provides an instance of your AuthService class
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Provides a stream of Firebase User? (null if signed out)
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authState;
});

Future<void> loadUserDataOnce(WidgetRef ref, String uid) async {
  final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  final user = UserModel.fromMap(userDoc.data()!, id: userDoc.id);
  ref.read(userProvider.notifier).state = user;
}