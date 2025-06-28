import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of auth state changes (signed in or signed out)
  Stream<User?> get authState => _auth.authStateChanges();

  // Get current user (optional helper)
  User? getCurrentUser() => _auth.currentUser;

  // Login with email and password
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      // print("Login error: $e");
      return null;
    }
  }

  // Logout
  Future<void> logout() => _auth.signOut();
}
