import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../viewmodels/inventory_viewmodel.dart';
import '../../providers/auth_provider.dart';
import '../../providers/master_data_provider.dart';
import '../../utils/capitalize.dart';
import '../../models/master_data_model.dart'; // for InventoryMeta and MasterDataModel

class AddInventoryBottomSheet extends ConsumerStatefulWidget {
  const AddInventoryBottomSheet({super.key});

  @override
  ConsumerState<AddInventoryBottomSheet> createState() =>
      _AddInventoryBottomSheetState();
}

class _AddInventoryBottomSheetState
    extends ConsumerState<AddInventoryBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _unitCtrl = TextEditingController();
  final TextEditingController _typeCtrl = TextEditingController();

  String? selectedItemName;
  int quantity = 0;
  int lowStockThreshold = 10;
  bool _saving = false;

  @override
  void dispose() {
    _unitCtrl.dispose();
    _typeCtrl.dispose();
    super.dispose();
  }

  InventoryMeta? _findByName(List<InventoryMeta> items, String? name) {
    if (name == null) return null;
    try {
      return items.firstWhere(
        (e) => e.name.toLowerCase().trim() == name.toLowerCase().trim(),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final masterDataAsync = ref.watch(masterDataProvider);

    return masterDataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('Error loading master data: $error')),
      data: (masterData) {
        final inventoryTypes = masterData.inventoryTypes;
        final itemNames = inventoryTypes
            .map((e) => e.name)
            .where((e) => e.isNotEmpty)
            .toList();

        // Initialize default once
        if (selectedItemName == null && itemNames.isNotEmpty) {
          selectedItemName = itemNames.first;
          final meta = _findByName(inventoryTypes, selectedItemName);
          _unitCtrl.text = (meta?.unit ?? '').capitalize();
          _typeCtrl.text = (meta?.type ?? '').capitalize();
        }

        return SafeArea(
          top: false,
          child: Padding(
            padding: MediaQuery.of(
              context,
            ).viewInsets.add(const EdgeInsets.all(16)),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedItemName,
                      decoration: const InputDecoration(
                        labelText: 'Item Name',
                        border: OutlineInputBorder(),
                      ),
                      items: itemNames
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.capitalize()),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedItemName = val;
                          final meta = _findByName(inventoryTypes, val);
                          _unitCtrl.text = (meta?.unit ?? '').capitalize();
                          _typeCtrl.text = (meta?.type ?? '').capitalize();
                        });
                      },
                      validator: (val) =>
                          (val == null || val.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (int.tryParse(value) == null) {
                          return 'Enter valid number';
                        }
                        return null;
                      },
                      onSaved: (value) => quantity = int.parse(value!),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      readOnly: true,
                      controller: _unitCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      readOnly: true,
                      controller: _typeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Item Type',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      initialValue: '10',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Low Stock Threshold',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (int.tryParse(value) == null) {
                          return 'Enter valid number';
                        }
                        return null;
                      },
                      onSaved: (value) => lowStockThreshold = int.parse(value!),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(_saving ? 'Adding...' : 'Add Item'),
                      onPressed: _saving
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              _formKey.currentState!.save();

                              if (selectedItemName == null ||
                                  !itemNames.contains(selectedItemName)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select an item'),
                                  ),
                                );
                                return;
                              }

                              final meta = _findByName(
                                inventoryTypes,
                                selectedItemName,
                              );
                              if (meta == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Unknown item selected'),
                                  ),
                                );
                                return;
                              }

                              final repository = ref.read(
                                inventoryRepositoryProvider,
                              );
                              final userId = user?.uid ?? 'unknown';

                              setState(() => _saving = true);
                              try {
                                if (meta.type.trim() == 'Prepared'){
                                  if (meta.recipe.isEmpty) {
                                    // Decide: block or allow simple add
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Prepared item has no recipe configured.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  await repository
                                      .addPreparedItemWithDeductions(
                                        preparedName: meta.name,
                                        preparedQty: quantity,
                                        unit: meta.unit,
                                        updatedBy: userId,
                                        lowStockThreshold: lowStockThreshold,
                                        recipe: meta.recipe,
                                      );
                                } else {
                                  final itemData = {
                                    'itemName': meta.name,
                                    'quantity': quantity,
                                    'unit': meta.unit,
                                    'type': meta.type,
                                    'lowStockThreshold': lowStockThreshold,
                                    'lastUpdated': Timestamp.now(),
                                    'updatedBy': userId,
                                  };
                                  await repository.addInventory(itemData);
                                }

                                if (context.mounted) {
                                  Navigator.of(context).pop(true);
                                }
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to add item: $e'),
                                  ),
                                );
                              } finally {
                                if (mounted) setState(() => _saving = false);
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
