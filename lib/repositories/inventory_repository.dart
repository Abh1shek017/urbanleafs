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
  }

  /// Update existing inventory item by ID
  Future<void> updateInventory(
    String id,
    Map<String, dynamic> inventoryData,
  ) async {
    await collection.doc(id).update(inventoryData);
  }
}
