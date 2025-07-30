import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stock_history_model.dart'; // Update the path as per your folder structure

final stockHistoryProvider =
    FutureProvider.family<List<StockHistory>, String>((ref, itemId) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('inventory')
        .doc(itemId)
        .collection('history')
        .orderBy('timestamp', descending: true) 
        .limit(10)
        .get();

    return snapshot.docs
        .map((doc) => StockHistory.fromFirestore(doc.data()))
        .toList();
  } catch (e) {
    throw Exception('Failed to fetch stock history: $e');
  }
});
