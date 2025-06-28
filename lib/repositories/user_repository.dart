import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'base_repository.dart';

class UserRepository extends BaseRepository {
  UserRepository() : super(FirebaseFirestore.instance.collection('users'));

  /// Get all users (Admin only)
  Stream<List<UserModel>> getAllUsers() {
    return collection.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => UserModel.fromSnapshot(doc)).toList(),
    );
  }

  /// Get a single user by ID
  Stream<UserModel> getUserById(String userId) {
    return collection
        .doc(userId)
        .snapshots()
        .map((doc) => UserModel.fromSnapshot(doc));
  }

  /// Get a single user by ID (one-time fetch)
  Future<UserModel?> getUserByIdOnce(String userId) async {
    final doc = await collection.doc(userId).get();
    if (doc.exists) {
      return UserModel.fromSnapshot(doc);
    }
    return null;
  }

  /// Create a new user with a specific ID (if needed)
  Future<void> createUser(String userId, Map<String, dynamic> userData) async {
    await collection.doc(userId).set(userData);
  }

  /// Create a new user with auto ID
  Future<DocumentReference> createUserAutoId(Map<String, dynamic> userData) {
    return collection.add(userData);
  }

  /// Update an existing user
  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    await collection.doc(userId).update(userData);
  }

  /// Delete a user
  Future<void> deleteUser(String userId) async {
    await collection.doc(userId).delete();
  }
}
