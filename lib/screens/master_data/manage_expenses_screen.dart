import 'package:flutter/material.dart';
import '../../services/master_data_service.dart';
import '../../widgets/glass_cards.dart';
import '../../utils/staggered_animation.dart';
import '../../widgets/admin_checker.dart';
import '../../utils/unique_list_utils.dart';

class ManageExpensesScreen extends StatefulWidget {
  const ManageExpensesScreen({super.key});

  @override
  State<ManageExpensesScreen> createState() => _ManageExpensesScreenState();
}

class _ManageExpensesScreenState extends State<ManageExpensesScreen> {
  final MasterDataService _service = MasterDataService();
  List<String> _expenseTypes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _service.loadLocalMasterData();
    final expenseTypes = UniqueListUtils.safeUniqueStringList(data['expenseTypes']);
    if (!mounted) return;

    if (expenseTypes.isEmpty) {
      final fresh = await _service.fetchAndUpdateFromFirestore();
      if (!mounted) return;
      setState(() => _expenseTypes = UniqueListUtils.safeUniqueStringList(fresh['expenseTypes']));
    } else {
      setState(() => _expenseTypes = expenseTypes);
    }
  }

  Future<void> _pullRefresh() async {
    final fresh = await _service.fetchAndUpdateFromFirestore();
    if (!mounted) return;
    setState(() => _expenseTypes = UniqueListUtils.safeUniqueStringList(fresh['expenseTypes']));
  }

  void _addItem() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Expense Type"),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: "Type"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = ctrl.text.trim();
              if (text.isEmpty) {
                _showError("Type cannot be empty.");
                return;
              }

              // ✅ Duplicate check (case-insensitive)
              final isDuplicate = _expenseTypes.any(
                (type) => type.toLowerCase() == text.toLowerCase(),
              );
              if (isDuplicate) {
                _showError("This expense type already exists.");
                return;
              }

              // ✅ Clone list and add
              final updatedList = List<String>.from(_expenseTypes)..add(text);

              setState(() => _expenseTypes = updatedList);

              // ✅ Write to Firestore and local JSON simultaneously
              await Future.wait([
                _service.updateMasterField('expenseTypes', _expenseTypes),
              ]);

              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _deleteItem(int i) async {
    final updatedList = List<String>.from(_expenseTypes)..removeAt(i);
    setState(() => _expenseTypes = updatedList);

    await Future.wait([
      _service.updateMasterField('expenseTypes', _expenseTypes),
    ]);

    await _loadData();
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
          appBar: AppBar(title: const Text("Manage Expenses")),
          floatingActionButton: isAdmin
              ? FloatingActionButton(
                  onPressed: _addItem,
                  child: const Icon(Icons.add),
                )
              : null,
          body: RefreshIndicator(
            onRefresh: isAdmin ? _pullRefresh : () async {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                itemCount: _expenseTypes.length,
                itemBuilder: (ctx, i) => StaggeredItem(
                  index: i,
                  child: GlassCard(
                    onTap: isAdmin ? () => _deleteItem(i) : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _expenseTypes[i],
                          style: Theme.of(context).textTheme.bodyLarge,
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
