import 'package:cloud_firestore/cloud_firestore.dart';

class StockHistory {
  final String type; // 'restock' or 'usage'
  final int quantity;
  final DateTime timestamp;

  StockHistory({
    required this.type,
    required this.quantity,
    required this.timestamp,
  });

  factory StockHistory.fromFirestore(Map<String, dynamic> data) {
    return StockHistory(
      type: data['type'] ?? 'unknown',
      quantity: data['quantity'] ?? 0,
      timestamp: (data['timestamp'] as Timestamp).toDate(), // changed
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'quantity': quantity,
      'timestamp': Timestamp.fromDate(timestamp), // changed
    };
  }
}
