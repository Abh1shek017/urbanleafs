import 'package:flutter/material.dart';
import '../../services/master_data_service.dart';
import '../../widgets/glass_cards.dart';
import '../../utils/staggered_animation.dart';
import '../../widgets/admin_checker.dart';
import '../../utils/unique_list_utils.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  final MasterDataService _service = MasterDataService();
  List<String> _orderItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _service.loadLocalMasterData();
    if (!mounted) return;
    final orderItems = UniqueListUtils.safeUniqueStringList(data['orderItems']);
    if (orderItems.isEmpty) {
      final fresh = await _service.fetchAndUpdateFromFirestore();
      if (!mounted) return;
      setState(() {
        _orderItems = UniqueListUtils.safeUniqueStringList(fresh['orderItems']);
        _loading = false;
      });
    } else {
      setState(() {
        _orderItems = orderItems;
        _loading = false;
      });
    }
  }

  Future<void> _pullRefresh() async {
    final fresh = await _service.fetchAndUpdateFromFirestore();
    if (!mounted) return;
    setState(() {
      _orderItems = UniqueListUtils.safeUniqueStringList(fresh['orderItems']);
    });
  }

  Future<void> _addItem() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Order Item"),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: "Item"),
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
              final newItem = ctrl.text.trim();
              if (newItem.isNotEmpty && !_orderItems.contains(newItem)) {
                setState(() => _orderItems.add(newItem));
                await _service.updateMasterField('orderItems', _orderItems);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _deleteItem(int i) async {
    setState(() => _orderItems.removeAt(i));
    await _service.updateMasterField('orderItems', _orderItems);
  }

  @override
  Widget build(BuildContext context) {
    return AdminChecker(
      builder: (context, isAdmin) {
        return Scaffold(
          appBar: AppBar(title: const Text("Manage Orders")),
          floatingActionButton: isAdmin
              ? FloatingActionButton(
                  onPressed: _addItem,
                  child: const Icon(Icons.add),
                )
              : null,
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: isAdmin ? _pullRefresh : () async {},
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _orderItems.isEmpty
                        ? const Center(child: Text("No Order Items Found"))
                        : ListView.builder(
                            itemCount: _orderItems.length,
                            itemBuilder: (ctx, i) => StaggeredItem(
                              index: i,
                              child: GlassCard(
                                onTap: isAdmin ? () => _deleteItem(i) : null,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _orderItems[i],
                                        style: Theme.of(context).textTheme.bodyLarge,
                                      ),
                                    ),
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
