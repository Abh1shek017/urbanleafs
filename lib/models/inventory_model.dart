import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryModel {
  final String id;
  final String itemName;
  final int quantity;
  final String unit;
  final DateTime lastUpdated;
  final String updatedBy;

  final String type; // 'raw' or 'prepared'
  final int lowStockThreshold; // optional, default to 10 if missing

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
    final data = snapshot.data() as Map<String, dynamic>;

    return InventoryModel(
      id: snapshot.id,
      itemName: data['itemName'] ?? '',
      quantity: data['quantity'] ?? 0,
      unit: data['unit'] ?? '',
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      updatedBy: data['updatedBy'] ?? '',
      type: data['type'] ?? 'raw',
      lowStockThreshold: data['lowStockThreshold'] ?? 10,
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
}
