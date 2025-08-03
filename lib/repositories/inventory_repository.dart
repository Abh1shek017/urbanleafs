import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_model.dart';
import '../utils/notifications_util.dart';
import 'base_repository.dart';
import 'package:intl/intl.dart';
import '../models/master_data_model.dart';

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

  Future<void> addPreparedItemWithDeductions({
    required String preparedName,
    required num preparedQty,
    required String unit,
    required String updatedBy,
    required num lowStockThreshold,
    required List<RecipeStep> recipe,
    bool preventNegative = true,
  }) async {
    final nowTs = Timestamp.now();
    final preparedId =
        '${preparedName.replaceAll(' ', '')}_${unit.replaceAll(' ', '')}_prepared';
    final preparedRef = collection.doc(preparedId);

    try {
      await collection.firestore.runTransaction((tx) async {
        // 1) Upsert prepared item
        final preparedSnap = await tx.get(preparedRef);
        num currentPrepared = 0;
        if (preparedSnap.exists) {
          final data = preparedSnap.data() as Map<String, dynamic>? ?? {};
          currentPrepared = (data['quantity'] as num?) ?? 0;
          tx.update(preparedRef, {
            'itemName': preparedName,
            'unit': unit,
            'type': 'prepared',
            'lowStockThreshold': lowStockThreshold,
            'quantity': (currentPrepared + preparedQty),
            'lastUpdated': nowTs,
            'updatedBy': updatedBy,
          });
        } else {
          tx.set(preparedRef, {
            'itemName': preparedName,
            'unit': unit,
            'type': 'prepared',
            'lowStockThreshold': lowStockThreshold,
            'quantity': preparedQty,
            'createdAt': nowTs,
            'lastUpdated': nowTs,
            'updatedBy': updatedBy,
          });
        }

        String _historyId(String itemName, String type, num qty) {
          final safeName = itemName.replaceAll(' ', '');
          final qtyStr = qty.toString();
          final formattedDate = DateFormat(
            'yyyyMMdd_HHmmss',
          ).format(DateTime.now());
          return '${safeName}$type${qtyStr}$formattedDate';
        }

        final histIdPrepared = _historyId(preparedName, 'prepare', preparedQty);
        tx.set(preparedRef.collection('history').doc(histIdPrepared), {
          'type': 'prepare',
          'quantity': preparedQty,
          'timestamp': nowTs,
          'addedBy': updatedBy,
        });

        // 2) Deduct raw items
        for (final step in recipe) {
          final rawName = step.rawName;
          final consume = (preparedQty * step.ratio).toDouble();

          final rawQuery = await collection
              .where('itemName', isEqualTo: rawName)
              .where('type', isEqualTo: 'Raw Material')
              .limit(1)
              .get();

          if (rawQuery.docs.isEmpty) {
            // dubg// Print('❌ Raw material "$rawName" not found.');
            throw StateError('Raw material "$rawName" not found.');
          }

          final rawDoc = rawQuery.docs.first;
          final rawRef = rawDoc.reference;
          final rawData = rawDoc.data() as Map<String, dynamic>? ?? {};
          final currentRaw = (rawData['quantity'] as num?)?.toDouble() ?? 0.0;
          final newQty = currentRaw - consume;

          if (preventNegative && newQty < 0) {
            // dubg// Print('❌ Not enough stock for $rawName: $currentRaw available, $consume needed');
            throw StateError(
              'Insufficient "$rawName" stock. Need $consume, available $currentRaw.',
            );
          }

          tx.update(rawRef, {
            'quantity': newQty,
            'lastUpdated': nowTs,
            'updatedBy': updatedBy,
          });

          final histIdRaw = _historyId(rawName, 'consume', consume);
          tx.set(rawRef.collection('history').doc(histIdRaw), {
            'type': 'consume',
            'quantity': consume,
            'timestamp': nowTs,
            'addedBy': updatedBy,
            'relatedPrepared': preparedName,
          });
        }
      });

      // dubg// Print('✅ Prepared item "$preparedName" added with deductions.');
    } catch (e) {
      // dubg// Print('🔥 Failed to add prepared item: $e\n$st');
      rethrow;
    }
  }

  String historyId(String itemName, String type, num qty) {
    final name = itemName.replaceAll(' ', '');
    final quantityStr = qty.toString();
    final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return '${name}$type$quantityStr$formattedDate';
  }

  /// Add inventory item - if exists, update quantity instead of creating duplicate
  Future<DocumentReference> addInventory(
    Map<String, dynamic> inventoryData,
  ) async {
    final itemName = inventoryData['itemName'] as String? ?? '';
    final unit = inventoryData['unit'] as String? ?? '';
    final type = inventoryData['type'] as String? ?? 'Raw Material';
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
