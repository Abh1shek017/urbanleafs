import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryModel {
  final String id;
  final String itemName;
  final int quantity;
  final String unit;
  final DateTime lastUpdated;
  final String updatedBy;
  final String type; // 'raw' or 'prepared'
  final int lowStockThreshold;

  InventoryModel({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.lastUpdated,
    required this.updatedBy,
    required this.type,
    required this.lowStockThreshold,
  });

  factory InventoryModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>? ?? {};

    return InventoryModel(
      id: snapshot.id,
      itemName: data['itemName'] ?? '',
      quantity: _parseInt(data['quantity']),
      unit: data['unit'] ?? '',
      lastUpdated: _parseTimestamp(data['lastUpdated']),
      updatedBy: data['updatedBy'] ?? '',
      type: data['type'] ?? 'raw',
      lowStockThreshold: _parseInt(data['lowStockThreshold'], defaultValue: 10),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'quantity': quantity,
      'unit': unit,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'updatedBy': updatedBy,
      'type': type,
      'lowStockThreshold': lowStockThreshold,
    };
  }

  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return defaultValue;
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.now();
  }
}
