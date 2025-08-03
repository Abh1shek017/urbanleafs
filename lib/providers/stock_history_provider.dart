import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stock_history_model.dart'; // Update the path as per your folder structure


final stockHistoryStreamProvider =
    StreamProvider.family<List<StockHistory>, String>((ref, itemId) {
  return FirebaseFirestore.instance
      .collection('inventory')
      .doc(itemId)
      .collection('history')
      .orderBy('timestamp', descending: true)
      .limit(10)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => StockHistory.fromFirestore(doc.data())).toList();
      });
});
