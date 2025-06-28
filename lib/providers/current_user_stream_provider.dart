import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urbanleafs/providers/user_provider.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

final currentUserStreamProvider = StreamProvider<UserModel?>((ref) {
  final authUserAsync = ref.watch(authStateProvider);

  if (authUserAsync.isLoading || authUserAsync.hasError) {
    return const Stream.empty();
  }

  final authUser = authUserAsync.value;
  if (authUser == null) return Stream.value(null);

  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository.getUserById(authUser.uid);
});
