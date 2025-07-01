import 'package:flutter/material.dart';
import '../../services/master_data_service.dart';
import '../../widgets/glass_cards.dart';
import '../../utils/staggered_animation.dart';
import '../../widgets/admin_checker.dart';
import '../../utils/unique_list_utils.dart';

class ManageCustomersScreen extends StatefulWidget {
  const ManageCustomersScreen({super.key});

  @override
  State<ManageCustomersScreen> createState() => _ManageCustomersScreenState();
}

class _ManageCustomersScreenState extends State<ManageCustomersScreen> {
  final MasterDataService _service = MasterDataService();
  List<dynamic> _customers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _service.loadLocalMasterData();
    final customers = UniqueListUtils.safeUniqueStringList(data['customers']);
    if (customers.isEmpty) {
      final fresh = await _service.fetchAndUpdateFromFirestore();
      setState(() => _customers = UniqueListUtils.safeUniqueStringList(fresh['customers']));
    } else {
      setState(() => _customers = customers);
    }
  }

  Future<void> _pullRefresh() async {
    final fresh = await _service.fetchAndUpdateFromFirestore();
    setState(() => _customers = UniqueListUtils.safeUniqueStringList(fresh['customers']));
  }

  void _addCustomer() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Customer"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Phone")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final newCustomer = "${nameCtrl.text.trim()} (${phoneCtrl.text.trim()})";
              setState(() => _customers.add(newCustomer));
              await _service.updateMasterField('customers', _customers);
              await _loadData();
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _deleteCustomer(int index) async {
    setState(() => _customers.removeAt(index));
    await _service.updateMasterField('customers', _customers);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return AdminChecker(
      builder: (context, isAdmin) {
        return Scaffold(
          appBar: AppBar(title: const Text("Manage Customers")),
          floatingActionButton: isAdmin 
            ? FloatingActionButton(onPressed: _addCustomer, child: const Icon(Icons.add))
            : null,
          body: RefreshIndicator(
            onRefresh: isAdmin ? _pullRefresh : () async {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                itemCount: _customers.length,
                itemBuilder: (ctx, i) => StaggeredItem(
                  index: i,
                  child: GlassCard(
                    onTap: isAdmin ? () => _deleteCustomer(i) : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_customers[i], style: Theme.of(context).textTheme.bodyLarge),
                        if (isAdmin)
                          const Icon(Icons.delete_outline, color: Colors.red),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
