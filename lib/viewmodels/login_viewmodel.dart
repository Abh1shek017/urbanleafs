import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../providers/local_storage_provider.dart';
import '../providers/auth_provider.dart';
import '../services/local_storage_service.dart';
class LoginState {
  final bool isLoading;
  final String? error;
  final bool isLoggedIn;

  LoginState({
    this.isLoading = false,
    this.error,
    this.isLoggedIn = false,
  });

  LoginState copyWith({
    bool? isLoading,
    String? error,
    bool? isLoggedIn,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

class LoginNotifier extends StateNotifier<LoginState> {
  final AuthService _authService;
  final LocalStorageService _localStorage;

  LoginNotifier(this._authService, this._localStorage) : super(LoginState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authService.login(email, password);
      if (user != null) {
        // Save user login status
        await _localStorage.saveUserLoggedIn(true);
        await _localStorage.saveUserId(user.uid);
        await _localStorage.saveUserRole('admin'); // In future, fetch from Firestore

        state = state.copyWith(isLoading: false, isLoggedIn: true);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: "Invalid credentials",
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = LoginState();
  }
}

final loginViewModelProvider =
    StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final localStorage = ref.watch(localStorageServiceProvider);
  return LoginNotifier(authService, localStorage);
});