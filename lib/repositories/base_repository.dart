import 'package:cloud_firestore/cloud_firestore.dart';

class BaseRepository {
  final CollectionReference collection;

  BaseRepository(this.collection);

  Stream<List<Map<String, dynamic>>> getAllAsStream() {
    return collection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  Future<void> addData(Map<String, dynamic> data) {
    return collection.add(data);
  }

  Future<void> updateData(String id, Map<String, dynamic> data) {
    return collection.doc(id).update(data);
  }

  Future<void> deleteData(String id) {
    return collection.doc(id).delete();
  }
}