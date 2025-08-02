import 'package:flutter/material.dart';
import '../../services/master_data_service.dart';
import '../../widgets/glass_cards.dart';
import '../../utils/staggered_animation.dart';
import '../../widgets/admin_checker.dart';

class ManageInventoryScreen extends StatefulWidget {
  const ManageInventoryScreen({super.key});

  @override
  State<ManageInventoryScreen> createState() => _ManageInventoryScreenState();
}

class _ManageInventoryScreenState extends State<ManageInventoryScreen> {
  final MasterDataService _service = MasterDataService();

  List<Map<String, dynamic>> _inventoryItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  Future<void> _loadLocalData() async {
    final data = await _service.loadLocalMasterData();
    if (!mounted) return;
    setState(() {
      _inventoryItems = List<Map<String, dynamic>>.from(
        data['inventoryTypes'] ?? [],
      );
      _loading = false;
    });
  }

  Future<void> _refreshFromFirestore() async {
    setState(() => _loading = true);
    final data = await _service.fetchAndUpdateFromFirestore();
    if (!mounted) return;
    setState(() {
      _inventoryItems = List<Map<String, dynamic>>.from(
        data['inventoryTypes'] ?? [],
      );
      _loading = false;
    });
  }

  Future<void> _addInventoryItemDialog() async {
    final nameController = TextEditingController();
    final unitController = TextEditingController();
    final typeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 12,
        backgroundColor: Colors.white,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Add Inventory Item",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Item Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: unitController,
                  decoration: const InputDecoration(
                    labelText: "Unit",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: typeController,
                  decoration: const InputDecoration(
                    labelText: "Type",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final unit = unitController.text.trim();
                        final type = typeController.text.trim();

                        if (name.isEmpty || unit.isEmpty || type.isEmpty) {
                          _showError("All fields are required.");
                          return;
                        }

                        final isDuplicate = _inventoryItems.any(
                          (item) =>
                              item['name'].toString().toLowerCase() ==
                              name.toLowerCase(),
                        );

                        if (isDuplicate) {
                          _showError("This item already exists.");
                          return;
                        }

                        final newItem = {
                          'name': name,
                          'unit': unit,
                          'type': type,
                        };

                        final updatedList = [..._inventoryItems, newItem];

                        setState(() {
                          _inventoryItems = updatedList;
                        });

                        await _service.updateMasterField(
                          'inventoryTypes',
                          updatedList,
                        );

                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text("Add"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteItem(int index) async {
    final updatedList = List<Map<String, dynamic>>.from(_inventoryItems)
      ..removeAt(index);

    setState(() {
      _inventoryItems = updatedList;
    });

    await _service.updateMasterField('inventoryTypes', updatedList);
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminChecker(
      builder: (context, isAdmin) {
        return Scaffold(
          appBar: AppBar(title: const Text("Manage Inventory Master Data")),
          floatingActionButton: isAdmin
              ? FloatingActionButton(
                  onPressed: _addInventoryItemDialog,
                  child: const Icon(Icons.add),
                )
              : null,
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: isAdmin ? _refreshFromFirestore : () async {},
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _inventoryItems.isEmpty
                        ? const Center(
                            child: Text("No inventory items found. Add some!"),
                          )
                        : ListView.builder(
                            itemCount: _inventoryItems.length,
                            itemBuilder: (ctx, i) {
                              final item = _inventoryItems[i];
                              return StaggeredItem(
                                index: i,
                                child: GlassCard(
                                  onTap: null, // ✅ disable tap to delete
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['name'],
                                              style: Theme.of(
                                                context,
                                              ).textTheme.headlineMedium,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Unit: ${item['unit']} | Type: ${item['type']}',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleMedium,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isAdmin)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          onPressed: () async {
                                            final shouldDelete = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text(
                                                  "Confirm Delete",
                                                ),
                                                content: const Text(
                                                  "Are you sure you want to delete this item?",
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          ctx,
                                                          false,
                                                        ),
                                                    child: const Text("Cancel"),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          ctx,
                                                          true,
                                                        ),
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                    child: const Text("Delete"),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (shouldDelete == true) {
                                              _deleteItem(i);
                                            }
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
        );
      },
    );
  }
}
