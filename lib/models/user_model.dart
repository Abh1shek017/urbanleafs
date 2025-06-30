import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, regular }

class UserModel {
  final String id;
  final String username;
  final String password;
  final UserRole role;
  final DateTime createdAt;
  final String? profileImageUrl;

  UserModel({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    required this.createdAt,
    this.profileImageUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, {required String id}) {
    final roleStr = (map['role'] ?? 'regular').toString().toLowerCase();
    final role = UserRole.values.firstWhere(
      (e) => e.name == roleStr,
      orElse: () => UserRole.regular,
    );

    final timestamp = map['createdAt'] as Timestamp?;
    final createdAt = timestamp?.toDate() ?? DateTime.now();

    return UserModel(
      id: id,
      username: map['username']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      role: role,
      createdAt: createdAt,
      profileImageUrl: map['profileImageUrl']?.toString(),
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
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
    };
  }

  @override
  String toString() {
    return 'UserModel(username: $username, role: ${role.name}, profileImageUrl: $profileImageUrl)';
  }
}
