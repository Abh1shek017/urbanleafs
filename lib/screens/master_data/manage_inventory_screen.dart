import 'package:flutter/material.dart';
import '../../services/json_storage_service.dart';
import '../../widgets/glass_cards.dart';
import '../../utils/staggered_animation.dart';

class ManageInventoryScreen extends StatefulWidget {
  const ManageInventoryScreen({super.key});

  @override
  State<ManageInventoryScreen> createState() => _ManageInventoryScreenState();
}

class _ManageInventoryScreenState extends State<ManageInventoryScreen>
    with SingleTickerProviderStateMixin {
  final JsonStorageService _service = JsonStorageService();

  List<dynamic> _inventoryTypes = [];
  List<dynamic> _units = [];
  List<dynamic> _itemTypes = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _service.getMasterData();
    setState(() {
      _inventoryTypes = data['inventoryTypes'] ?? [];
      _units = data['units'] ?? [];
      _itemTypes = data['itemTypes'] ?? [];
    });
  }

  Future<void> _addItemDialog(String field, List<dynamic> list) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Add ${field.capitalize()}"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: field.capitalize()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final newItem = controller.text.trim();
              if (newItem.isNotEmpty) {
                setState(() {
                  list.add(newItem);
                });
                _service.updateMasterDataField(field, list);
              }
              Navigator.pop(ctx);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _deleteItem(String field, List<dynamic> list, int index) {
    setState(() => list.removeAt(index));
    _service.updateMasterDataField(field, list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Inventory Master Data"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Items"),
            Tab(text: "Units"),
            Tab(text: "Types"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final idx = _tabController.index;
          if (idx == 0) _addItemDialog('inventoryTypes', _inventoryTypes);
          if (idx == 1) _addItemDialog('units', _units);
          if (idx == 2) _addItemDialog('itemTypes', _itemTypes);
        },
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildList('inventoryTypes', _inventoryTypes),
            _buildList('units', _units),
            _buildList('itemTypes', _itemTypes),
          ],
        ),
      ),
    );
  }

  Widget _buildList(String field, List<dynamic> list) {
    if (list.isEmpty) {
      return Center(child: Text("No $field found. Add some!"));
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (ctx, i) => StaggeredItem(
        index: i,
        child: GlassCard(
          onTap: () => _deleteItem(field, list, i),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                list[i],
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Icon(Icons.delete_outline, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() =>
      isEmpty ? "" : '${this[0].toUpperCase()}${substring(1)}';
}
