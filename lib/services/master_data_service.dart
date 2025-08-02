import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/master_data_model.dart';

class MasterDataService {
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<Map<String, dynamic>> loadLocalMasterData() async {
final prefs = await SharedPreferences.getInstance();
final jsonString = prefs.getString('masterData');
if (jsonString == null || jsonString.isEmpty) return {};
try {
final decoded = jsonDecode(jsonString);
return decoded is Map<String, dynamic> ? decoded : {};
} catch (_) {
return {};
}
}

Future<MasterDataModel> getMasterDataModel() async {
final localJson = await loadLocalMasterData();
return MasterDataModel.fromJson(localJson);
}

Future<void> updateLocalMasterData(Map<String, dynamic> data) async {
final prefs = await SharedPreferences.getInstance();
await prefs.setString('masterData', jsonEncode(data));
}

Future<Map<String, dynamic>> fetchAndUpdateFromFirestore() async {
final doc = await _firestore.collection('masterData').doc('global').get();
final data = doc.data() ?? {};
await updateLocalMasterData(data);
return data;
}

Future<void> updateMasterField(String field, dynamic value) async {
final docRef = _firestore.collection('masterData').doc('global');


if (field == 'inventoryTypes' && value is List) {
  for (final item in value) {
    final map = Map<String, dynamic>.from(item as Map);
    final name = (map['name'] ?? '').toString().trim();
    final unit = (map['unit'] ?? '').toString().trim();
    final type = (map['type'] ?? '').toString().trim();
    if (name.isEmpty || unit.isEmpty || type.isEmpty) {
      throw Exception('Invalid inventoryType entry: $item');
    }
  }
}

await docRef.set({field: value}, SetOptions(merge: true));
await fetchAndUpdateFromFirestore();
}

Future<void> updateFirestoreFieldArray(String field, String newValue) async {
final docRef = _firestore.collection('masterData').doc('global');
final snap = await docRef.get();
final data = snap.data() ?? {};


if (data[field] == null) {
  await docRef.set({field: [newValue]}, SetOptions(merge: true));
} else {
  await docRef.update({field: FieldValue.arrayUnion([newValue])});
}

await fetchAndUpdateFromFirestore();
}

Future<void> removeFirestoreFieldArray(String field, String valueToRemove) async {
final docRef = _firestore.collection('masterData').doc('global');
final snap = await docRef.get();
final data = snap.data() ?? {};


if (data[field] != null) {
  await docRef.update({field: FieldValue.arrayRemove([valueToRemove])});
}

await fetchAndUpdateFromFirestore();
}

// Optional: realtime
Stream<MasterDataModel> masterDataStream() {
return _firestore
.collection('masterData')
.doc('global')
.snapshots()
.map((snap) {
final data = snap.data() ?? {};
updateLocalMasterData(data);
return MasterDataModel.fromJson(data);
});
}
}