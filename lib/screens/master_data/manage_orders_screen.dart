import 'package:flutter/material.dart';
import '../../services/json_storage_service.dart';
import '../../widgets/glass_cards.dart';
import '../../utils/staggered_animation.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  final JsonStorageService _service = JsonStorageService();
  List<dynamic> _orderItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _service.getMasterData();
    setState(() => _orderItems = data['orderItems'] ?? []);
  }

  void _addItem() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Order Item"),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: "Item")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              setState(() => _orderItems.add(controller.text.trim()));
              _service.updateMasterDataField('orderItems', _orderItems);
              Navigator.pop(ctx);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _deleteItem(int index) {
    setState(() => _orderItems.removeAt(index));
    _service.updateMasterDataField('orderItems', _orderItems);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Orders")),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: _orderItems.length,
          itemBuilder: (ctx, i) => StaggeredItem(
            index: i,
            child: GlassCard(
              onTap: () => _deleteItem(i),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_orderItems[i], style: Theme.of(context).textTheme.bodyLarge),
                  const Icon(Icons.delete_outline, color: Colors.red),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
