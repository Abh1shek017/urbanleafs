import 'package:flutter/material.dart';
import '../../services/master_data_service.dart';
import '../../widgets/glass_cards.dart';
import '../../widgets/admin_checker.dart';

class ManageInventoryScreen extends StatefulWidget {
  const ManageInventoryScreen({super.key});

  @override
  State<ManageInventoryScreen> createState() => _ManageInventoryScreenState();
}

class _ManageInventoryScreenState extends State<ManageInventoryScreen>
    with SingleTickerProviderStateMixin {
  final MasterDataService _service = MasterDataService();

  List<Map<String, dynamic>> _inventoryItems = [];
  bool _loading = true;
  late TabController _tabController;
  Map<String, dynamic>? _selectedPreparedItem;
  List<Map<String, dynamic>> _recipeSteps = [];

  @override
  void initState() {
    super.initState();
    _loadLocalData();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {}); // rebuild to update FAB on tab change
    });
  }

  List<Map<String, dynamic>> get _rawItems {
    return _inventoryItems
        .where((e) {
          final type = (e['type'] ?? '').toString().toLowerCase();
          // Adjust the matching as per your data ("raw", "raw material", etc.)
          return type.contains('raw');
        })
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalData() async {
    final data = await _service.loadLocalMasterData();
    if (!mounted) return;
    setState(() {
      _inventoryItems = List<Map<String, dynamic>>.from(
        data['inventoryTypes'] ?? [],
      );
      _selectDefaultPrepared();
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

  void _selectDefaultPrepared() {
    final prepared = _inventoryItems.firstWhere(
      (e) => (e['type'] ?? '').toString().toLowerCase() == 'prepared',
      orElse: () => {},
    );
    if (prepared.isNotEmpty) {
      _selectedPreparedItem = prepared;
      _recipeSteps = List<Map<String, dynamic>>.from(
        prepared['recipe'] ?? const [],
      );
    } else {
      _selectedPreparedItem = null;
      _recipeSteps = [];
    }
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

  Future<void> _saveRecipeForSelected() async {
    if (_selectedPreparedItem == null) return;

    final name = _selectedPreparedItem!['name'];
    // Update in local _inventoryItems by name match
    final idx = _inventoryItems.indexWhere((e) => (e['name'] ?? '') == name);
    if (idx == -1) return;

    final updatedItem = Map<String, dynamic>.from(_inventoryItems[idx]);
    updatedItem['recipe'] = _recipeSteps;

    final updatedList = List<Map<String, dynamic>>.from(_inventoryItems);
    updatedList[idx] = updatedItem;

    setState(() => _inventoryItems = updatedList);
    await _service.updateMasterField('inventoryTypes', updatedList);
  }

  void _selectPreparedByName(String? name) {
    if (name == null) return;
    final found = _inventoryItems.firstWhere(
      (e) =>
          (e['type'] ?? '').toString().toLowerCase() == 'prepared' &&
          (e['name'] ?? '') == name,
      orElse: () => {},
    );
    setState(() {
      if (found.isNotEmpty) {
        _selectedPreparedItem = found;
        _recipeSteps = List<Map<String, dynamic>>.from(
          found['recipe'] ?? const [],
        );
      } else {
        _selectedPreparedItem = null;
        _recipeSteps = [];
      }
    });
  }

  Future<void> _addRecipeStepDialog() async {
    if (_selectedPreparedItem == null) {
      _showError('Select a prepared item first.');
      return;
    }

    final rawItems = _rawItems;
    if (rawItems.isEmpty) {
      _showError('No raw material items found in master data.');
      return;
    }

    String? selectedRawName;
    final ratioCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Recipe Step'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Raw Material',
                border: OutlineInputBorder(),
              ),
              value: selectedRawName,
              items: rawItems.map<DropdownMenuItem<String>>((e) {
                final name = (e['name'] ?? '').toString();
                return DropdownMenuItem<String>(value: name, child: Text(name));
              }).toList(),
              onChanged: (val) {
                selectedRawName = val;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ratioCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Ratio (per 1 prepared unit)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final ratio = double.tryParse(ratioCtrl.text.trim());
      if ((selectedRawName == null || selectedRawName!.isEmpty) ||
          ratio == null) {
        _showError('Select a raw material and enter a numeric ratio.');
        return;
      }

      // Optional: prevent duplicates for the same rawName
      final alreadyExists = _recipeSteps.any(
        (s) => (s['rawName'] ?? '').toString() == selectedRawName,
      );
      if (alreadyExists) {
        _showError('This raw material is already in the recipe.');
        return;
      }

      setState(() {
        _recipeSteps = [
          ..._recipeSteps,
          {'rawName': selectedRawName, 'ratio': ratio},
        ];
      });
      await _saveRecipeForSelected();
    }
  }

  void _deleteRecipeStep(int index) async {
    setState(() {
      _recipeSteps = List<Map<String, dynamic>>.from(_recipeSteps)
        ..removeAt(index);
    });
    await _saveRecipeForSelected();
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

  Widget _buildItemsTab(bool isAdmin) {
    return RefreshIndicator(
      onRefresh: isAdmin ? _refreshFromFirestore : () async {},
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _inventoryItems.isEmpty
            ? const Center(child: Text('No inventory items found. Add some!'))
            : ListView.builder(
                itemCount: _inventoryItems.length,
                itemBuilder: (ctx, i) {
                  final item = _inventoryItems[i];
                  return GlassCard(
                    onTap: null,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                style: Theme.of(context).textTheme.titleMedium,
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
                                  title: const Text('Confirm Delete'),
                                  content: const Text(
                                    'Are you sure you want to delete this item?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (shouldDelete == true) _deleteItem(i);
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildRecipesTab(bool isAdmin) {
    // Build prepared items list
    final List<Map<String, dynamic>> preparedItems = _inventoryItems
        .where((e) => (e['type'] ?? '').toString().toLowerCase() == 'prepared')
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPreparedItem?['name']?.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Prepared Item',
                    border: OutlineInputBorder(),
                  ),
                  items: preparedItems.map<DropdownMenuItem<String>>((
                    Map<String, dynamic> e,
                  ) {
                    final name = (e['name'] ?? '').toString();
                    return DropdownMenuItem<String>(
                      value: name,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: isAdmin
                      ? (val) => _selectPreparedByName(val)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              if (isAdmin)
                ElevatedButton.icon(
                  onPressed: () async {
                    await _refreshFromFirestore();
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _selectedPreparedItem == null
                ? const Center(child: Text('No prepared item selected'))
                : (_recipeSteps.isEmpty
                      ? const Center(
                          child: Text('No recipe steps. Add some using +'),
                        )
                      : ListView.separated(
                          itemCount: _recipeSteps.length,
                          separatorBuilder: (context, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final step = _recipeSteps[i];
                            return GlassCard(
                              child: ListTile(
                                title: Text(step['rawName']?.toString() ?? ''),
                                subtitle: Text(
                                  'Ratio: ${(step['ratio'] as num?)?.toDouble() ?? 0.0}',
                                ),
                                trailing: isAdmin
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _deleteRecipeStep(i),
                                      )
                                    : null,
                              ),
                            );
                          },
                        )),
          ),
          if (isAdmin)
            const Text(
              'Note: Ratio means quantity of raw required to produce 1 unit of prepared item.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
          backgroundColor: Colors.grey[50], // optional: improve contrast
          appBar: AppBar(
            title: const Text('Manage Inventory Master Data'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Items'),
                Tab(text: 'Recipes'),
              ],
            ),
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildItemsTab(isAdmin),
                    _buildRecipesTab(isAdmin),
                  ],
                ),
          floatingActionButton: isAdmin
              ? (_tabController.index == 0
                    ? FloatingActionButton(
                        onPressed: _addInventoryItemDialog,
                        child: const Icon(Icons.add),
                      )
                    : FloatingActionButton.extended(
                        onPressed: _addRecipeStepDialog,
                        icon: const Icon(Icons.playlist_add),
                        label: const Text('Add Step'),
                      ))
              : null,
        );
      },
    );
  }
}
