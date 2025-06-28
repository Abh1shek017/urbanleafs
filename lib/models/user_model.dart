import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, regular }

class UserModel {
  final String id;
  final String username;
  final String password;
  final UserRole role;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, {required String id}) {
    // 🔥 FIXED: This converts "admin" → UserRole.admin correctly
    final roleStr = (map['role'] ?? 'regular').toString().toLowerCase();
    final role = UserRole.values.firstWhere(
      (e) => e.name == roleStr,
      orElse: () => UserRole.regular,
    );

    final timestamp = map['createdAt'] as Timestamp?;
    final createdAt = timestamp?.toDate() ?? DateTime.now();

    return UserModel(
      id: id,
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      role: role,
      createdAt: createdAt,
    );
  }

  factory UserModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap(data, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'role': role.name, // ✅ Only saves "admin" or "regular"
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // ✅ Optional: for debugging
  @override
  String toString() {
    return 'UserModel(username: $username, role: ${role.name})';
  }
}
