import 'package:flutter/material.dart';
import '../../services/master_data_service.dart';
import '../../widgets/glass_cards.dart';
import '../../utils/staggered_animation.dart';
import '../../widgets/admin_checker.dart';
import '../../utils/unique_list_utils.dart';

class ManageInventoryScreen extends StatefulWidget {
  const ManageInventoryScreen({super.key});

  @override
  State<ManageInventoryScreen> createState() => _ManageInventoryScreenState();
}

class _ManageInventoryScreenState extends State<ManageInventoryScreen>
    with SingleTickerProviderStateMixin {
  final MasterDataService _service = MasterDataService();

  List<String> _inventoryTypes = [];
  List<String> _units = [];
  List<String> _itemTypes = [];

  late TabController _tabController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLocalData();
  }

  Future<void> _loadLocalData() async {
    final data = await _service.loadLocalMasterData();
    if (!mounted) return;
    setState(() {
      _inventoryTypes = UniqueListUtils.safeUniqueStringList(data['inventoryTypes']);
      _units = UniqueListUtils.safeUniqueStringList(data['units']);
      _itemTypes = UniqueListUtils.safeUniqueStringList(data['itemTypes']);
      _loading = false;
    });
  }

  Future<void> _refreshFromFirestore() async {
    setState(() => _loading = true);
    final data = await _service.fetchAndUpdateFromFirestore();
    if (!mounted) return;
    setState(() {
      _inventoryTypes = UniqueListUtils.safeUniqueStringList(data['inventoryTypes']);
      _units = UniqueListUtils.safeUniqueStringList(data['units']);
      _itemTypes = UniqueListUtils.safeUniqueStringList(data['itemTypes']);
      _loading = false;
    });
  }

  Future<void> _addItemDialog(String field, List<String> list) async {
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
            onPressed: () {
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newItem = controller.text.trim();
              if (newItem.isNotEmpty && !list.contains(newItem)) {
                setState(() => list.add(newItem));
                await _service.updateMasterField(field, list);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _deleteItem(String field, List<String> list, int index) async {
    setState(() => list.removeAt(index));
    await _service.updateMasterField(field, list);
  }

  @override
  Widget build(BuildContext context) {
    return AdminChecker(
      builder: (context, isAdmin) {
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
          floatingActionButton: isAdmin
              ? FloatingActionButton(
                  onPressed: () {
                    final idx = _tabController.index;
                    if (idx == 0) _addItemDialog('inventoryTypes', _inventoryTypes);
                    if (idx == 1) _addItemDialog('units', _units);
                    if (idx == 2) _addItemDialog('itemTypes', _itemTypes);
                  },
                  child: const Icon(Icons.add),
                )
              : null,
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: isAdmin ? _refreshFromFirestore : () async {},
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildList('inventoryTypes', _inventoryTypes, isAdmin),
                        _buildList('units', _units, isAdmin),
                        _buildList('itemTypes', _itemTypes, isAdmin),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildList(String field, List<String> list, bool isAdmin) {
    if (list.isEmpty) {
      return Center(child: Text("No ${field.capitalize()} found. Add some!"));
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (ctx, i) => StaggeredItem(
        index: i,
        child: GlassCard(
          onTap: isAdmin ? () => _deleteItem(field, list, i) : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  list[i],
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              if (isAdmin)
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
