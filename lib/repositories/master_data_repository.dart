import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/master_data_model.dart';

class MasterDataRepository {
MasterDataRepository({
FirebaseFirestore? firestore,
this.collectionPath = 'masterData',
this.documentId = 'general',
}) : _firestore = firestore ?? FirebaseFirestore.instance;

final FirebaseFirestore _firestore;
final String collectionPath;
final String documentId;

Future<MasterDataModel> fetchMasterData() async {
final docRef = _firestore.collection(collectionPath).doc(documentId);
final snap = await docRef.get();


if (!snap.exists) {
  throw Exception('Master data not found at $collectionPath/$documentId');
}

final data = snap.data();
if (data == null) {
  throw Exception('Master data document is empty at $collectionPath/$documentId');
}

try {
  return MasterDataModel.fromJson(data);
} catch (e) {
  // Helps diagnose schema mismatches
  throw Exception('Failed to parse master data: $e');
}
}

// Optional: realtime stream
Stream<MasterDataModel> streamMasterData() {
final docRef = _firestore.collection(collectionPath).doc(documentId);
return docRef.snapshots().map((snap) {
if (!snap.exists || snap.data() == null) {
throw Exception('Master data not found at $collectionPath/$documentId');
}
return MasterDataModel.fromJson(snap.data()!);
});
}
}
