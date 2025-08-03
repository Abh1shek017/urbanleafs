import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/master_data_model.dart';

class MasterDataService {
  MasterDataService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'masterData';
  static const String _docId = 'global';
  static const String _cacheKey = 'masterData';

  Future<Map<String, dynamic>> loadLocalMasterData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cacheKey);
    if (jsonString == null || jsonString.isEmpty) return {};
    try {
      final decoded = jsonDecode(jsonString);
      return decoded is Map<String, dynamic>
          ? Map<String, dynamic>.from(decoded)
          : {};
    } catch (e) {
      return {};
    }
  }

  Future<void> updateLocalMasterData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(data));
  }

  Future<Map<String, dynamic>> fetchAndUpdateFromFirestore() async {
    final doc = await _firestore.collection(_collection).doc(_docId).get();
    final data = doc.data() != null
        ? Map<String, dynamic>.from(doc.data()!)
        : <String, dynamic>{};
    await updateLocalMasterData(data);
    return data;
  }

  // Prefer this: it tries cache, then Firestore if empty.
  Future<MasterDataModel> getMasterDataModel() async {
    var localJson = await loadLocalMasterData();
    if (localJson.isEmpty) {
      localJson = await fetchAndUpdateFromFirestore();
    }
    return MasterDataModel.fromJson(localJson);
  }

  Future<void> updateMasterField(String field, dynamic value) async {
    final docRef = _firestore.collection(_collection).doc(_docId);

    // Validate inventoryTypes payload if updating it
    if (field == 'inventoryTypes' && value is List) {
      for (final item in value) {
        final map = Map<String, dynamic>.from(item as Map);
        final name = (map['name'] ?? '').toString().trim();
        final unit = (map['unit'] ?? '').toString().trim();
        final type = (map['type'] ?? '').toString().trim();
        if (name.isEmpty || unit.isEmpty || type.isEmpty) {
          throw Exception('Invalid inventoryType entry: $item');
        }

        // Validate recipe if present
        final recipeList =
            (map['recipe'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            const [];
        for (final step in recipeList) {
          final rawName = (step['rawName'] ?? '').toString().trim();
          final ratioVal = step['ratio'];
          final ratio = ratioVal is num ? ratioVal.toDouble() : double.nan;
          if (rawName.isEmpty || ratio.isNaN || ratio < 0) {
            throw Exception('Invalid recipe step in $name: $step');
          }
        }
      }
    }

    await docRef.set({field: value}, SetOptions(merge: true));
    await fetchAndUpdateFromFirestore();
  }

  Future<void> updateFirestoreFieldArray(String field, String newValue) async {
    final docRef = _firestore.collection(_collection).doc(_docId);
    final snap = await docRef.get();
    final data = snap.data() ?? {};

    if (data[field] == null) {
      await docRef.set({
        field: [newValue],
      }, SetOptions(merge: true));
    } else {
      await docRef.update({
        field: FieldValue.arrayUnion([newValue]),
      });
    }
    await fetchAndUpdateFromFirestore();
  }

  Future<void> removeFirestoreFieldArray(
    String field,
    String valueToRemove,
  ) async {
    final docRef = _firestore.collection(_collection).doc(_docId);
    final snap = await docRef.get();
    final data = snap.data() ?? {};

    if (data[field] != null) {
      await docRef.update({
        field: FieldValue.arrayRemove([valueToRemove]),
      });
    }
    await fetchAndUpdateFromFirestore();
  }

  // Realtime stream with cache sync
  Stream<MasterDataModel> masterDataStream() {
    return _firestore.collection(_collection).doc(_docId).snapshots().map((
      snap,
    ) {
      final data = snap.data() ?? <String, dynamic>{};
      // Fire and forget cache write
      updateLocalMasterData(data);
      return MasterDataModel.fromJson(Map<String, dynamic>.from(data));
    });
  }
}
