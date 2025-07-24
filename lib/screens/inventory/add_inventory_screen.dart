import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../viewmodels/inventory_viewmodel.dart';
import '../../providers/auth_provider.dart';
import '../../providers/master_data_provider.dart';
import '../../utils/capitalize.dart';

class AddInventoryBottomSheet extends ConsumerStatefulWidget {
  const AddInventoryBottomSheet({super.key});

  @override
  ConsumerState<AddInventoryBottomSheet> createState() =>
      _AddInventoryBottomSheetState();
}

class _AddInventoryBottomSheetState
    extends ConsumerState<AddInventoryBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  String? selectedItemName;
  String? selectedUnit;
  String? selectedType;
  int quantity = 0;
  int lowStockThreshold = 10;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final masterDataAsync = ref.watch(masterDataProvider);

    return masterDataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error loading master data: $error')),
      data: (masterData) {
        final itemNames = masterData.inventoryTypes;
        final units = masterData.units;
        final types = masterData.itemTypes;

        // Set default values if not already selected
        selectedItemName ??= itemNames.isNotEmpty ? itemNames.first : null;
        selectedUnit ??= units.isNotEmpty ? units.first : null;
        selectedType ??= types.isNotEmpty ? types.first : null;

        return Padding(
          padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedItemName,
                    decoration: const InputDecoration(labelText: "Item Name"),
                    items: itemNames
                        .map((item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.capitalize()),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => selectedItemName = val),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Quantity"),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Required";
                      if (int.tryParse(value) == null) return "Enter valid number";
                      return null;
                    },
                    onSaved: (value) => quantity = int.parse(value!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedUnit,
                    decoration: const InputDecoration(labelText: "Unit"),
                    items: units
                        .map((unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit.capitalize()),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => selectedUnit = val),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: "Item Type"),
                    items: types
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.capitalize()),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => selectedType = val),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: '10',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: "Low Stock Threshold"),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Required";
                      if (int.tryParse(value) == null) return "Enter valid number";
                      return null;
                    },
                    onSaved: (value) => lowStockThreshold = int.parse(value!),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Add Item"),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();

                        final itemData = {
                          'itemName': selectedItemName,
                          'quantity': quantity,
                          'unit': selectedUnit,
                          'type': selectedType,
                          'lowStockThreshold': lowStockThreshold,
                          'lastUpdated': Timestamp.now(),
                          'updatedBy': user?.uid ?? 'unknown',
                        };

                        try {
                          final repository = ref.read(inventoryRepositoryProvider);
                          await repository.addInventory(itemData);
                          if (context.mounted) {
                            Navigator.of(context).pop(true);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Failed to add item: $e")),
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
