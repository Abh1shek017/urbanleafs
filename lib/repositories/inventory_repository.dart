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
    String? size, // ✅ size added
    bool preventNegative = true,
  }) async {
    final nowTs = Timestamp.now();
    final preparedId =
        '${preparedName.replaceAll(' ', '')}_${unit.replaceAll(' ', '')}_Prepared${size != null ? "_${size.replaceAll(' ', '')}" : ""}';
    final preparedRef = collection.doc(preparedId);

    try {
      await collection.firestore.runTransaction((tx) async {
        // ==== 1. UPSERT PREPARED ITEM ====
        final preparedSnap = await tx.get(preparedRef);
        num currentPrepared = 0;

        if (preparedSnap.exists) {
          final data = preparedSnap.data() as Map<String, dynamic>? ?? {};
          currentPrepared = (data['quantity'] as num?) ?? 0;

          tx.update(preparedRef, {
            'itemName': preparedName,
            'unit': unit,
            'type': 'Prepared',
            'lowStockThreshold': lowStockThreshold,
            'quantity': ((currentPrepared + preparedQty.toDouble()) * 100)
                    .roundToDouble() /
                100,
            'lastUpdated': nowTs,
            'updatedBy': updatedBy,
            'size': size, // ✅ add size
          });
        } else {
          tx.set(preparedRef, {
            'itemName': preparedName,
            'unit': unit,
            'type': 'Prepared',
            'lowStockThreshold': lowStockThreshold,
            'quantity': (preparedQty.toDouble() * 100).roundToDouble() / 100,
            'createdAt': nowTs,
            'lastUpdated': nowTs,
            'updatedBy': updatedBy,
            'size': size, // ✅ add size
          });
        }

        // ==== 2. ADD HISTORY ENTRY FOR PREPARED ITEM ====
        String _historyId(String itemName, String actionType, num qty) {
          final safeName = itemName.replaceAll(' ', '');
          final qtyStr = qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);
          final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
          return '${safeName}_$actionType$qtyStr$formattedDate';
        }

        final histIdPrepared = _historyId(preparedName, 'prepared', preparedQty);
        tx.set(preparedRef.collection('history').doc(histIdPrepared), {
          'type': 'restock',
          'quantity': (preparedQty * 100).roundToDouble() / 100,
          'timestamp': nowTs,
          'addedBy': updatedBy,
        });

        // ==== 3. VALIDATE AND DEDUCT RAW MATERIALS ====
        for (final step in recipe) {
          final rawName = step.rawName.trim();
          final consumeQty = (preparedQty * step.ratio).toDouble();

          final rawQuery = await collection
              .where('itemName', isEqualTo: rawName)
              .where('type', isEqualTo: 'Raw Material')
              .limit(1)
              .get();

          if (rawQuery.docs.isEmpty) {
            throw StateError('Raw material "$rawName" not found.');
          }

          final rawDoc = rawQuery.docs.first;
          final rawRef = rawDoc.reference;
          final rawData = rawDoc.data() as Map<String, dynamic>? ?? {};
          final currentRaw = (rawData['quantity'] as num?)?.toDouble() ?? 0.0;
          final newQty = currentRaw - consumeQty;

          if (preventNegative && newQty < 0) {
            throw StateError(
              'Insufficient "$rawName" stock. Needed $consumeQty, available $currentRaw.',
            );
          }

          tx.update(rawRef, {
            'quantity': (newQty * 100).roundToDouble() / 100,
            'lastUpdated': nowTs,
            'updatedBy': updatedBy,
          });

          final histIdRaw = _historyId(rawName, 'consume', consumeQty);
          tx.set(rawRef.collection('history').doc(histIdRaw), {
            'type': 'consume',
            'quantity': (consumeQty * 100).roundToDouble() / 100,
            'timestamp': nowTs,
            'addedBy': updatedBy,
            'relatedPrepared': preparedName,
          });
        }
      });
    } catch (e) {
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
    final size = inventoryData['size'] as String?; // ✅ size added
    final quantityToAdd =
        (inventoryData['quantity'] as num?)?.toDouble() ?? 0.0;

    // 🔹 Custom document ID includes size
    final customDocId =
        '${itemName.replaceAll(' ', '')}_${unit.replaceAll(' ', '')}_${type.replaceAll(' ', '')}${size != null ? "_${size.replaceAll(' ', '')}" : ""}';

    final docRef = collection.doc(customDocId);
    final existingDoc = await docRef.get();

    if (existingDoc.exists) {
      final existingData = existingDoc.data() as Map<String, dynamic>? ?? {};
      final existingQuantity =
          (existingData['quantity'] as num?)?.toDouble() ?? 0.0;
      final newQuantity = existingQuantity + quantityToAdd;

      await docRef.update({
        'quantity': newQuantity,
        'lastUpdated': inventoryData['lastUpdated'],
        'updatedBy': inventoryData['updatedBy'],
        'type': inventoryData['type'],
        'unit': inventoryData['unit'],
        'size': size, // ✅ add size
        'lowStockThreshold': inventoryData['lowStockThreshold'],
      });

      final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final customId =
          '${itemName.replaceAll(' ', '_')}_restock${quantityToAdd}_$formattedDate';

      await docRef.collection('history').doc(customId).set({
        'type': 'restock',
        'quantity': quantityToAdd,
        'timestamp': Timestamp.now(),
        'addedBy': inventoryData['updatedBy'],
      });

      await _checkLowStockAndNotify({
        ...inventoryData,
        'quantity': newQuantity,
      });
    } else {
      await docRef.set({
        ...inventoryData,
        'size': size, // ✅ add size
      });

      final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final customId =
          '${itemName.replaceAll(' ', '_')}_restock${quantityToAdd}_$formattedDate';

      await docRef.collection('history').doc(customId).set({
        'type': 'restock',
        'quantity': quantityToAdd,
        'timestamp': Timestamp.now(),
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
      final quantity = (inventoryData['quantity'] as num?)?.toDouble() ?? 0.0;
      final lowStockThreshold =
          (inventoryData['lowStockThreshold'] as num?)?.toDouble() ?? 10.0;

      final itemName = inventoryData['itemName'] as String? ?? 'Unknown Item';
      final unit = inventoryData['unit'] as String? ?? 'units';
      final size = inventoryData['size'] as String?;

      if (quantity <= lowStockThreshold) {
        await addNotification(
          'inventory',
          'Low Inventory',
          '$itemName${size != null ? " ($size)" : ""} low: only $quantity $unit left',
        );
      }
    } catch (e) {
      // Don't fail inventory update if notification fails
    }
  }
}
