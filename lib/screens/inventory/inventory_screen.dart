import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/notifications_util.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/inventory_model.dart';
import '../../repositories/inventory_repository.dart';
import '../../providers/user_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final inventoryAsync = ref.watch(inventoryStreamProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text("Inventory Status")),
      body: inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No inventory items found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isLowStock = item.quantity < item.lowStockThreshold;
              final isRaw = item.type == 'raw';

              final userNameAsync = ref.watch(userNameByIdProvider(item.updatedBy));

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Row(
                    children: [
                      Text(
                        item.itemName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      if (isLowStock)
                        const Icon(Icons.warning, color: Colors.red, size: 18),
                      if (!isLowStock)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 18,
                        ),
                    ],
                  ),
                  subtitle: userNameAsync.when(
                    data: (name) => Text(
                      'Qty: ${item.quantity} ${item.unit}\nType: ${item.type.toUpperCase()}\nUpdated by: $name',
                      style: TextStyle(
                        color: isRaw ? Colors.orange : Colors.teal,
                      ),
                    ),
                    loading: () => Text(
                      'Qty: ${item.quantity} ${item.unit}\nType: ${item.type.toUpperCase()}\nUpdated by: ...',
                      style: TextStyle(
                        color: isRaw ? Colors.orange : Colors.teal,
                      ),
                    ),
                    error: (_, __) => Text(
                      'Qty: ${item.quantity} ${item.unit}\nType: ${item.type.toUpperCase()}\nUpdated by: Unknown',
                      style: TextStyle(
                        color: isRaw ? Colors.orange : Colors.teal,
                      ),
                    ),
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditInventoryDialog(
                      context,
                      item,
                      user?.uid ?? '',
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddInventoryDialog(context, user?.uid ?? ''),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  void _showInventoryFormDialog({
    required BuildContext context,
    required String userId,
    InventoryModel? item,
  }) {
    final formKey = GlobalKey<FormState>();
    String itemName = item?.itemName ?? '';
    int quantity = item?.quantity ?? 0;
    String unit = item?.unit ?? 'kg';
    String type = item?.type ?? 'raw';
    int lowStockThreshold = item?.lowStockThreshold ?? 10;

    final isEdit = item != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: formKey,
            child: Wrap(
              runSpacing: 12,
              children: [
                DropdownButtonFormField<String>(
                  value: itemName.isNotEmpty ? itemName : null,
                  decoration: const InputDecoration(labelText: 'Item Name'),
                  items: ['Wheat', 'Oil', 'Plates', 'Rolls']
                      .map(
                        (name) => DropdownMenuItem(value: name, child: Text(name)),
                      )
                      .toList(),
                  onChanged: (val) => itemName = val!,
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  initialValue: quantity.toString(),
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    if (int.tryParse(val) == null) return 'Invalid number';
                    return null;
                  },
                  onSaved: (val) => quantity = int.parse(val!),
                ),
                DropdownButtonFormField<String>(
                  value: unit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: ['kg', 'pcs', 'litre']
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (val) => unit = val!,
                ),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ['raw', 'prepared']
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (val) => type = val!,
                ),
                TextFormField(
                  initialValue: lowStockThreshold.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Low Stock Threshold',
                  ),
                  keyboardType: TextInputType.number,
                  onSaved: (val) => lowStockThreshold = int.parse(val!),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();

                      final repo = InventoryRepository();
                      final data = {
                        'itemName': itemName,
                        'quantity': quantity,
                        'unit': unit,
                        'type': type,
                        'lowStockThreshold': lowStockThreshold,
                        'lastUpdated': Timestamp.now(),
                        'updatedBy': userId,
                      };

                     if (isEdit) {
  await repo.updateInventory(item.id, data);
  await addNotification(
    title: 'Inventory Updated',
    body: '${itemName} updated to $quantity $unit',
  ); // ✅
} else {
  await repo.addInventory(data);
  await addNotification(
    title: 'New Inventory Item',
    body: '$itemName added with $quantity $unit',
  ); // ✅
}


                      if (context.mounted) Navigator.of(context).pop();
                    }
                  },
                  icon: Icon(isEdit ? Icons.save : Icons.add),
                  label: Text(isEdit ? 'Update Item' : 'Add Item'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddInventoryDialog(BuildContext context, String userId) {
    _showInventoryFormDialog(context: context, userId: userId);
  }

  void _showEditInventoryDialog(
    BuildContext context,
    InventoryModel item,
    String userId,
  ) {
    _showInventoryFormDialog(context: context, userId: userId, item: item);
  }
}
