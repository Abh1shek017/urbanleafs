import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_model.dart';
import '../utils/notifications_util.dart';
import 'base_repository.dart';

class InventoryRepository extends BaseRepository {
  InventoryRepository()
      : super(FirebaseFirestore.instance.collection('inventory'));

  /// Stream of all inventory items (real-time)
  Stream<List<InventoryModel>> getAllInventory() {
    return collection.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => InventoryModel.fromSnapshot(doc)).toList(),
    );
  }

  /// Stream to calculate total inventory quantity (real-time)
  Stream<double> getTotalInventoryStock() {
    return getAllInventory().map(
      (items) =>
          items.fold(0.0, (total, item) => total + (item.quantity.toDouble())),
    );
  }

  /// Add inventory item - if exists, update quantity instead of creating duplicate
  Future<void> addInventory(Map<String, dynamic> inventoryData) async {
    final itemName = inventoryData['itemName'] as String? ?? '';
    final unit = inventoryData['unit'] as String? ?? '';
    final type = inventoryData['type'] as String? ?? 'raw';
    final quantityToAdd = inventoryData['quantity'] as int? ?? 0;

    // 🔹 Custom document ID: combine item name, unit, and type
    final customDocId = '${itemName.trim()}_${unit.trim()}_${type.trim()}';

    final existingDoc = await collection.doc(customDocId).get();

    if (existingDoc.exists) {
      // ✅ Item exists, merge quantity
      final existingData = existingDoc.data() as Map<String, dynamic>? ?? {};
      final newQuantity = (existingData['quantity'] ?? 0) + quantityToAdd;

      await collection.doc(customDocId).update({
        'quantity': newQuantity,
        'lastUpdated': inventoryData['lastUpdated'],
        'updatedBy': inventoryData['updatedBy'],
        'type': inventoryData['type'],
        'unit': inventoryData['unit'],
        'lowStockThreshold': inventoryData['lowStockThreshold'],
      });

      await _checkLowStockAndNotify({
        ...inventoryData,
        'quantity': newQuantity,
      });
    } else {
      // ✅ Item does not exist, create new document with custom ID
      await collection.doc(customDocId).set(inventoryData);
      await _checkLowStockAndNotify(inventoryData);
    }
  }

  /// Update existing inventory item by ID
  Future<void> updateInventory(
    String id,
    Map<String, dynamic> inventoryData,
  ) async {
    await collection.doc(id).update(inventoryData);
    await _checkLowStockAndNotify(inventoryData);
  }

  /// ✅ Check if inventory is low and create notification
  Future<void> _checkLowStockAndNotify(
    Map<String, dynamic> inventoryData,
  ) async {
    try {
      final quantity = inventoryData['quantity'] as int? ?? 0;
      final lowStockThreshold = inventoryData['lowStockThreshold'] as int? ?? 10;
      final itemName = inventoryData['itemName'] as String? ?? 'Unknown Item';
      final unit = inventoryData['unit'] as String? ?? 'units';

      if (quantity <= lowStockThreshold) {
        await addNotification(
          'inventory',
          'Low Inventory',
          '$itemName low: only $quantity $unit left',
        );
      }
    } catch (e) {
      // Don't fail inventory update if notification fails
    }
  }
}
