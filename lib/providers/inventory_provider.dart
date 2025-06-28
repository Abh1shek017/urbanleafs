import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/inventory_repository.dart';
import '../models/inventory_model.dart';

final inventoryRepositoryProvider =
    Provider<InventoryRepository>((ref) => InventoryRepository());

final inventoryStreamProvider = StreamProvider.autoDispose<List<InventoryModel>>(
    (ref) => ref.watch(inventoryRepositoryProvider).getAllInventory());