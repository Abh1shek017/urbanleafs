import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/inventory_provider.dart';
import '../../widgets/inventory_item.dart';

class InventoryListScreen extends ConsumerStatefulWidget {
  const InventoryListScreen({super.key});

  @override
  ConsumerState<InventoryListScreen> createState() =>
      _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  String _selectedFilter = 'all'; // 'all', 'raw', 'prepared'

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Inventory")),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text("All"),
                    selected: _selectedFilter == 'all',
                    onSelected: (_) {
                      setState(() => _selectedFilter = 'all');
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text("Raw"),
                    selected: _selectedFilter == 'raw',
                    onSelected: (_) {
                      setState(() => _selectedFilter = 'raw');
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text("Prepared"),
                    selected: _selectedFilter == 'prepared',
                    onSelected: (_) {
                      setState(() => _selectedFilter = 'prepared');
                    },
                  ),
                ],
              ),
            ),

            // Inventory List
            Expanded(
              child: inventoryAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text("Error: $err")),
                data: (inventoryItems) {
                  final filteredItems = _selectedFilter == 'all'
                      ? inventoryItems
                      : inventoryItems
                            .where((item) => item.type == _selectedFilter)
                            .toList();

                  if (filteredItems.isEmpty) {
                    return const Center(
                      child: Text("No inventory items found."),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return InventoryItem(
                        item: item,
                        onEdit: () {
                          // TODO: Implement Edit Navigation
                          // Navigator.pushNamed(context, '/inventory/edit', arguments: item);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Add New Inventory FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('add_inventory'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
