import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_model.dart';
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

  /// Add new inventory item
  Future<void> addInventory(Map<String, dynamic> inventoryData) async {
    await collection.add(inventoryData);

    // ✅ Check for low stock and create notification
    await _checkLowStockAndNotify(inventoryData);
  }

  /// Update existing inventory item by ID
  Future<void> updateInventory(
    String id,
    Map<String, dynamic> inventoryData,
  ) async {
    await collection.doc(id).update(inventoryData);

    // ✅ Check for low stock and create notification
    await _checkLowStockAndNotify(inventoryData);
  }

  /// ✅ Check if inventory is low and create notification
  Future<void> _checkLowStockAndNotify(
    Map<String, dynamic> inventoryData,
  ) async {
    try {
      final quantity = inventoryData['quantity'] as int? ?? 0;
      final lowStockThreshold =
          inventoryData['lowStockThreshold'] as int? ?? 10;
      final itemName = inventoryData['itemName'] as String? ?? 'Unknown Item';
      final unit = inventoryData['unit'] as String? ?? 'units';

      if (quantity <= lowStockThreshold) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'title': 'Low Inventory',
          'body': '$itemName low: only $quantity $unit left',
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Don't fail inventory update if notification fails
      print('Failed to create low inventory notification: $e');
    }
  }
}
