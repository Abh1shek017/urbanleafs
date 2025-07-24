import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/inventory_repository.dart';
import '../models/inventory_model.dart';

// Repository Provider
final inventoryRepositoryProvider = Provider<InventoryRepository>(
    (ref) => InventoryRepository());

// 🔹 Stream of all inventory items (auto-refreshes on any change)
final allInventoryStreamProvider =
    StreamProvider.autoDispose<List<InventoryModel>>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getAllInventory();
});

// Future to add new inventory item
final addInventoryItemFutureProvider = FutureProvider.family<void, Map<String, dynamic>>(
  (ref, itemData) async {
    final repository = ref.watch(inventoryRepositoryProvider);
    await repository.addInventory(itemData);
  },
);

// Future to update existing inventory item
final updateInventoryItemFutureProvider = FutureProvider.family<void, Map<String, dynamic>>(
  (ref, args) async {
    final repository = ref.watch(inventoryRepositoryProvider);
    final String itemId = args['id'] as String;
    final Map<String, dynamic> updateData = args['data'] as Map<String, dynamic>;
    await repository.updateInventory(itemId, updateData);
  },
);