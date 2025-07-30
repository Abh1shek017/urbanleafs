import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/master_data_model.dart';

class MasterDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Loads local master data JSON from SharedPreferences
  Future<Map<String, dynamic>> loadLocalMasterData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('masterData') ?? '{}';
    return jsonDecode(jsonString);
  }
Future<MasterDataModel> getMasterDataModel() async {
  final localJson = await loadLocalMasterData();
  return MasterDataModel.fromJson(localJson);
}

  /// Updates local SharedPreferences cache
  Future<void> updateLocalMasterData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('masterData', jsonEncode(data));
  }

  /// Fetches Firestore master data document, updates local JSON, returns map
  Future<Map<String, dynamic>> fetchAndUpdateFromFirestore() async {
    final doc = await _firestore.collection('masterData').doc('global').get();
    final data = doc.data() ?? {};
    // print('✅ Fetched Firestore data: $data');
    await updateLocalMasterData(data);
    return data;
  }

  /// Overwrites a field (like 'customers') with a full list
  Future<void> updateMasterField(String field, List<dynamic> value) async {
    final docRef = _firestore.collection('masterData').doc('global');
    await docRef.set({field: value}, SetOptions(merge: true));
    print("✅ Overwrote field '$field' with: $value");
    await fetchAndUpdateFromFirestore(); // refresh local cache
  }

  /// Adds a single value to a Firestore array field and updates local JSON
  Future<void> updateFirestoreFieldArray(String field, String newValue) async {
    final docRef = _firestore.collection('masterData').doc('global');

    final snap = await docRef.get();
    final data = snap.data() ?? {};

    if (data[field] == null) {
      // Field does not exist or is null, initialize with array containing newValue
      await docRef.set({ field: [newValue] }, SetOptions(merge: true));
      print("✅ Field '$field' was missing. Created new array with: $newValue");
    } else {
      // Field exists, safe to use arrayUnion
      await docRef.update({
        field: FieldValue.arrayUnion([newValue])
      });
      print("✅ Field '$field' exists. Added using arrayUnion: $newValue");
    }

    final freshData = await fetchAndUpdateFromFirestore();
    await updateLocalMasterData(freshData);
  }

  /// Removes a single value from a Firestore array field and updates local JSON
  Future<void> removeFirestoreFieldArray(String field, String valueToRemove) async {
    final docRef = _firestore.collection('masterData').doc('global');

    final snap = await docRef.get();
    final data = snap.data() ?? {};

    if (data[field] != null) {
      await docRef.update({
        field: FieldValue.arrayRemove([valueToRemove])
      });
      print("✅ Removed '$valueToRemove' from '$field'");
    } else {
      print("⚠️ Tried to remove from '$field', but field does not exist.");
    }

    final freshData = await fetchAndUpdateFromFirestore();
    await updateLocalMasterData(freshData);
  }
}
