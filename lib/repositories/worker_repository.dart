import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/worker_model.dart';

class WorkerRepository {
  final _firestore = FirebaseFirestore.instance;
  CollectionReference get _workerRef => _firestore.collection('workers');

  Future<void> addWorker(WorkerModel worker) async {
    final docRef = _workerRef.doc();
    final newWorker = worker.copyWith(id: docRef.id);
    await docRef.set(newWorker.toMap());
  }

  Future<List<WorkerModel>> getWorkers() async {
    final snapshot = await _workerRef.where('isActive', isEqualTo: true).get();
    return snapshot.docs.map((doc) => WorkerModel.fromDoc(doc)).toList();
  }

  /// ✅ Add this method
  Stream<List<WorkerModel>> getAllWorkersStream() {
    return _workerRef
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => WorkerModel.fromDoc(doc)).toList());
  }

  /// ✅ Add this method
  Future<bool> checkIfWorkerExists(String mobile) async {
    final snapshot =
        await _workerRef.where('phone', isEqualTo: mobile).limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> deactivateWorker(String id) async {
    await _workerRef.doc(id).update({'isActive': false});
  }
}
