import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/user_repository.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';
// Provider for UserRepository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

// StreamProvider: Get current logged-in user data
final currentUserStreamProvider = StreamProvider.autoDispose<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value(null);

  final repository = ref.watch(userRepositoryProvider);
  return repository.getUserById(authState.uid);
});

// StreamProvider: Get all users (Admin only)
final allUsersStreamProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getAllUsers();
});

// FutureProvider: Update user role (Admin only)
final updateUserRoleFutureProvider = FutureProvider.family<void, Map<String, dynamic>>(
    (ref, args) async {
  final repository = ref.watch(userRepositoryProvider);
  final String userId = args['userId'];
  final String newRole = args['role'];

  await repository.updateUser(userId, {'role': newRole});
});
final userNameByIdProvider = FutureProvider.family<String, String>((ref, uid) async {
  final repository = ref.watch(userRepositoryProvider);
  final user = await repository.getUserByIdOnce(uid); // we'll add this method next
  return user?.username ?? 'Unknown';
});

final userProvider = StateProvider<UserModel?>((ref) => null);
