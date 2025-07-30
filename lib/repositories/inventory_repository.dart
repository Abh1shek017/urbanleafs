import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_model.dart';
import '../utils/notifications_util.dart';
import 'base_repository.dart';
import 'package:intl/intl.dart';

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
  Future<DocumentReference> addInventory(
    Map<String, dynamic> inventoryData,
  ) async {
    final itemName = inventoryData['itemName'] as String? ?? '';
    final unit = inventoryData['unit'] as String? ?? '';
    final type = inventoryData['type'] as String? ?? 'raw';
    final quantityToAdd = inventoryData['quantity'] as int? ?? 0;

    // 🔹 Custom document ID
    final customDocId =
        '${itemName.replaceAll(' ', '')}_${unit.replaceAll(' ', '')}_${type.replaceAll(' ', '')}';

    final docRef = collection.doc(customDocId);
    final existingDoc = await docRef.get();

    if (existingDoc.exists) {
      // ✅ Item exists: update quantity
      final existingData = existingDoc.data() as Map<String, dynamic>? ?? {};
      final newQuantity = (existingData['quantity'] ?? 0) + quantityToAdd;

      await docRef.update({
        'quantity': newQuantity,
        'lastUpdated': inventoryData['lastUpdated'],
        'updatedBy': inventoryData['updatedBy'],
        'type': inventoryData['type'],
        'unit': inventoryData['unit'],
        'lowStockThreshold': inventoryData['lowStockThreshold'],
      });

      // ✅ Add history entry
      final itemName =
          inventoryData['itemName']?.toString().replaceAll(' ', '_') ?? 'item';
      final type = 'restock';
      final quantityStr = quantityToAdd.toString();

      final formattedDate = DateFormat(
        'yyyyMMdd_HHmmss',
      ).format(DateTime.now());
      final customId = '${itemName}_$type${quantityStr}_$formattedDate';

      await docRef.collection('history').doc(customId).set({
        'type': type,
        'quantity': quantityToAdd,
        'timestamp': Timestamp.now(),
        'addedBy': inventoryData['updatedBy'],
      });

      await _checkLowStockAndNotify({
        ...inventoryData,
        'quantity': newQuantity,
      });
    } else {
      // ✅ Item does not exist: create new
      await docRef.set(inventoryData);

      final itemName =
          inventoryData['itemName']?.toString().replaceAll(' ', '_') ?? 'item';
      final type = 'restock';
      final quantityStr = quantityToAdd.toString();

      // Format: yyyyMMdd_HHmmss (e.g., 20250730_235959)
      final formattedDate = DateFormat(
        'yyyyMMdd_HHmmss',
      ).format(DateTime.now());

      final customId = '${itemName}_$type${quantityStr}_$formattedDate';

      await docRef.collection('history').doc(customId).set({
        'type': type,
        'quantity': quantityToAdd,
        'timestamp':
            Timestamp.now(), // use 'timestamp' for consistency with your model
        'addedBy': inventoryData['updatedBy'],
      });

      await _checkLowStockAndNotify(inventoryData);
    }

    return docRef;
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
      final lowStockThreshold =
          inventoryData['lowStockThreshold'] as int? ?? 10;
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
