import 'package:cloud_firestore/cloud_firestore.dart';
class InventoryModel {
final String id;
final String itemName;
final double quantity; // allow fractional
final String unit;
final DateTime lastUpdated;
final String updatedBy;
final String type; // 'raw' or 'prepared'
final double lowStockThreshold; // allow fractional thresholds too

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
  itemName: (data['itemName'] ?? '').toString(),
  quantity: _parseDouble(data['quantity']),
  unit: (data['unit'] ?? '').toString(),
  lastUpdated: _parseTimestamp(data['lastUpdated']),
  updatedBy: (data['updatedBy'] ?? '').toString(),
  type: (data['type'] ?? 'raw').toString(),
  lowStockThreshold: _parseDouble(data['lowStockThreshold'], defaultValue: 10.0),
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

static double _parseDouble(dynamic value, {double defaultValue = 0.0}) {
if (value == null) return defaultValue;
if (value is num) return value.toDouble();
if (value is String) {
final v = double.tryParse(value);
if (v != null) return v;
}
return defaultValue;
}

static DateTime _parseTimestamp(dynamic value) {
if (value is Timestamp) return value.toDate();
if (value is DateTime) return value;
return DateTime.now();
}
}