import 'package:flutter/material.dart';
import '../../services/json_storage_service.dart';
import '../../widgets/glass_cards.dart';
import '../../utils/staggered_animation.dart';

class ManageCustomersScreen extends StatefulWidget {
  const ManageCustomersScreen({super.key});

  @override
  State<ManageCustomersScreen> createState() => _ManageCustomersScreenState();
}

class _ManageCustomersScreenState extends State<ManageCustomersScreen> {
  final JsonStorageService _service = JsonStorageService();
  List<dynamic> _customers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _service.getMasterData();
    setState(() => _customers = data['customers'] ?? []);
  }

  void _addCustomer() async {
    final controller = TextEditingController();
    final phoneController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Customer"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: controller, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Phone")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final newCustomer = "${controller.text.trim()} (${phoneController.text.trim()})";
              setState(() => _customers.add(newCustomer));
              _service.updateMasterDataField('customers', _customers);
              Navigator.pop(ctx);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _deleteCustomer(int index) {
    setState(() => _customers.removeAt(index));
    _service.updateMasterDataField('customers', _customers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Customers")),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCustomer,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: _customers.length,
          itemBuilder: (ctx, i) => StaggeredItem(
            index: i,
            child: GlassCard(
              onTap: () => _deleteCustomer(i),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_customers[i], style: Theme.of(context).textTheme.bodyLarge),
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
