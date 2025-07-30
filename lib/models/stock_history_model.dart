import 'package:cloud_firestore/cloud_firestore.dart';

class StockHistory {
  final String type; // 'restock' or 'usage'
  final int quantity;
  final DateTime date;

  StockHistory({
    required this.type,
    required this.quantity,
    required this.date,
  });

  factory StockHistory.fromFirestore(Map<String, dynamic> data) {
    return StockHistory(
      type: data['type'] ?? 'unknown',
      quantity: data['quantity'] ?? 0,
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'quantity': quantity,
      'date': Timestamp.fromDate(date),
    };
  }
}
