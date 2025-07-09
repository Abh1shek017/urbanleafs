import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/app_constants.dart';
import '../../viewmodels/inventory_viewmodel.dart';
import '../../providers/auth_provider.dart';
import '../../utils/capitalize.dart';

class AddInventoryScreen extends ConsumerWidget {
  const AddInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();

    String selectedItemName = AppConstants.inventoryItemNames[0];
    String selectedUnit = AppConstants.inventoryUnits[0];
    String selectedType = 'raw';
    int quantity = 0;
    int lowStockThreshold = 10;

    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text("Add New Inventory Item")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: selectedItemName,
                decoration: const InputDecoration(labelText: "Item Name"),
                items: AppConstants.inventoryItemNames
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.capitalize()),
                        ))
                    .toList(),
                onChanged: (val) => selectedItemName = val!,
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
                items: AppConstants.inventoryUnits
                    .map((unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit.capitalize()),
                        ))
                    .toList(),
                onChanged: (val) => selectedUnit = val!,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: "Item Type"),
                items: ['raw', 'prepared']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.capitalize()),
                        ))
                    .toList(),
                onChanged: (val) => selectedType = val!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: '10',
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: "Low Stock Threshold"),
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
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();

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
              )
            ],
          ),
        ),
      ),
    );
  }
}
