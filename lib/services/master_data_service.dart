import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MasterDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> loadLocalMasterData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('masterData') ?? '{}';
    return jsonDecode(jsonString);
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

  /// updates Firestore field and then also updates full local cache
  Future<void> updateMasterField(String field, List<dynamic> value) async {
    final docRef = _firestore.collection('masterData').doc('global');
    await docRef.set({field: value}, SetOptions(merge: true));
    await fetchAndUpdateFromFirestore(); // refresh local cache with latest
  }
  Future<void> updateFirestoreFieldArray(String field, String newValue) async {
  final docRef = _firestore.collection('masterData').doc('global');

  await docRef.update({
    field: FieldValue.arrayUnion([newValue])
  });

  // Optionally also update your local JSON after updating Firestore
  final freshData = await fetchAndUpdateFromFirestore();
  await updateLocalMasterData(freshData);
}
}
