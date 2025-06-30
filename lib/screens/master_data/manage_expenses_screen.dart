import 'package:flutter/material.dart';
import '../../services/json_storage_service.dart';
import '../../widgets/glass_cards.dart';
import '../../utils/staggered_animation.dart';

class ManageExpensesScreen extends StatefulWidget {
  const ManageExpensesScreen({super.key});

  @override
  State<ManageExpensesScreen> createState() => _ManageExpensesScreenState();
}

class _ManageExpensesScreenState extends State<ManageExpensesScreen> {
  final JsonStorageService _service = JsonStorageService();
  List<dynamic> _expenseTypes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _service.getMasterData();
    setState(() => _expenseTypes = data['expenseTypes'] ?? []);
  }

  void _addItem() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Expense Type"),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: "Type")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              setState(() => _expenseTypes.add(controller.text.trim()));
              _service.updateMasterDataField('expenseTypes', _expenseTypes);
              Navigator.pop(ctx);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _deleteItem(int index) {
    setState(() => _expenseTypes.removeAt(index));
    _service.updateMasterDataField('expenseTypes', _expenseTypes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Expenses")),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: _expenseTypes.length,
          itemBuilder: (ctx, i) => StaggeredItem(
            index: i,
            child: GlassCard(
              onTap: () => _deleteItem(i),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_expenseTypes[i], style: Theme.of(context).textTheme.bodyLarge),
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
