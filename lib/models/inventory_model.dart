import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryModel {
  final String id;
  final String itemName;
  final double quantity; // allow fractional
  final String unit;
  final String type; // 'raw' or 'prepared'
  final double lowStockThreshold; // allow fractional thresholds too
  final DateTime lastUpdated;
  final String updatedBy;
  final String? size; // optional size

  InventoryModel({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.type,
    required this.lowStockThreshold,
    required this.lastUpdated,
    required this.updatedBy,
    this.size,
  });

  factory InventoryModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>? ?? {};

    return InventoryModel(
      id: snapshot.id,
      itemName: (data['itemName'] ?? '').toString(),
      quantity: _parseDouble(data['quantity']),
      unit: (data['unit'] ?? '').toString(),
      type: (data['type'] ?? 'raw').toString(),
      lowStockThreshold: _parseDouble(data['lowStockThreshold'], defaultValue: 10.0),
      lastUpdated: _parseTimestamp(data['lastUpdated']),
      updatedBy: (data['updatedBy'] ?? '').toString(),
      size: (data['size'] != null && (data['size'] as String).isNotEmpty)
          ? data['size'].toString()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
  final map = <String, Object>{
    'itemName': itemName,
    'quantity': quantity,
    'unit': unit,
    'type': type,
    'lowStockThreshold': lowStockThreshold,
    'lastUpdated': Timestamp.fromDate(lastUpdated),
    'updatedBy': updatedBy,
  };

  // Only add size if it is not null
  if (size != null) {
    map['size'] = size!; // Use ! to cast String? to String (Object)
  }

  return map;
}


  // Utility to parse numbers safely
  static double _parseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) {
      final v = double.tryParse(value);
      if (v != null) return v;
    }
    return defaultValue;
  }

  // Utility to parse timestamps safely
  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
