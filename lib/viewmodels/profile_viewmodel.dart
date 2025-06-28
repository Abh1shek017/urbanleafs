import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // Added this
import '../services/firebase_service.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';

class ProfileState {
  final bool isLoading;
  final String? error;
  final UserModel? user;

  ProfileState({
    this.isLoading = false,
    this.error,
    this.user,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? error,
    UserModel? user,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      user: user ?? this.user,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final AuthService _authService;

  ProfileNotifier(this._authService) : super(ProfileState());

  Future<void> loadCurrentUser(WidgetRef ref) async {
    state = state.copyWith(isLoading: true, error: null);

    // Use watch to get AsyncValue<User?>
    final authStateAsync = ref.watch(authStateProvider);

    // If loading or null user, set loading false and return
    if (authStateAsync is AsyncLoading || authStateAsync.value == null) {
      state = state.copyWith(isLoading: false, user: null);
      return;
    }

    final authState = authStateAsync.value!;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(authState.uid)
          .get();

      final userData = snapshot.data();
      if (userData != null) {
        final user = UserModel(
          id: snapshot.id,
          username: userData['username'] ?? '',
          password: userData['passwordHash'] ?? '',
          role: userData['role'] ?? '',
          createdAt: (userData['createdAt'] as Timestamp).toDate(),
        );

        state = state.copyWith(isLoading: false, user: user);
      } else {
        state = state.copyWith(isLoading: false, user: null);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }
}

final profileViewModelProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return ProfileNotifier(authService);
});
