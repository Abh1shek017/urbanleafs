import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    await updateLocalMasterData(data);
    return data;
  }

  /// Overwrites a master field (like 'inventoryTypes', 'units', or 'itemTypes')
  Future<void> updateMasterField(String field, dynamic value) async {
    final docRef = _firestore.collection('masterData').doc('global');

    // Special handling for inventoryTypes if needed later
    if (field == 'inventoryTypes' && value is List<Map<String, dynamic>>) {
      // Ensure each map contains name, unit, and type
      for (var item in value) {
        if (!item.containsKey('name') ||
            !item.containsKey('unit') ||
            !item.containsKey('type')) {
          throw Exception("Invalid inventoryType entry: $item");
        }
      }
    }

    await docRef.set({field: value}, SetOptions(merge: true));
    await fetchAndUpdateFromFirestore(); // Refresh local cache
  }

  /// Adds a simple string value to a Firestore array field and updates local JSON
  Future<void> updateFirestoreFieldArray(String field, String newValue) async {
    final docRef = _firestore.collection('masterData').doc('global');

    final snap = await docRef.get();
    final data = snap.data() ?? {};

    if (data[field] == null) {
      // Field doesn't exist
      await docRef.set({
        field: [newValue],
      }, SetOptions(merge: true));
    } else {
      // Append using arrayUnion
      await docRef.update({
        field: FieldValue.arrayUnion([newValue]),
      });
    }

    final freshData = await fetchAndUpdateFromFirestore();
    await updateLocalMasterData(freshData);
  }

  /// Removes a string value from a Firestore array field and updates local JSON
  Future<void> removeFirestoreFieldArray(
    String field,
    String valueToRemove,
  ) async {
    final docRef = _firestore.collection('masterData').doc('global');

    final snap = await docRef.get();
    final data = snap.data() ?? {};

    if (data[field] != null) {
      await docRef.update({
        field: FieldValue.arrayRemove([valueToRemove]),
      });
    } else {
    }

    final freshData = await fetchAndUpdateFromFirestore();
    await updateLocalMasterData(freshData);
  }
}
