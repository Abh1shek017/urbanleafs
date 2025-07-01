import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_constants.dart';
import '../../models/expense_model.dart';
import '../../viewmodels/expense_viewmodel.dart';
import '../../services/master_data_service.dart';
import '../../utils/notifications_util.dart';

/// 🔥 Utility to load expense types safely from master data
Future<List<String>> _loadExpenseTypes() async {
  final masterDataService = MasterDataService();
  final masterData = await masterDataService.loadLocalMasterData();

  final raw = masterData['expenseTypes'];
  List<String> types;

  if (raw is List) {
    types = raw.map((e) => e.toString()).toList();
  } else if (raw is Map) {
    types = raw.values.map((e) => e.toString()).toList();
  } else {
    types = [];
  }

  return types.isNotEmpty
      ? types
      : [
          AppConstants.expenseRawMaterial,
          AppConstants.expenseTransportation,
          AppConstants.expenseLabor,
          AppConstants.expenseOther,
        ];
}

/// Show Add Expense Bottom Sheet
void showAddExpenseDialog(BuildContext context, WidgetRef ref) async {
  final formKey = GlobalKey<FormState>();
  String? description;
  double? amount;

  final expenseTypes = await _loadExpenseTypes();
  String type = expenseTypes.first;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Add New Expense",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: "Description"),
                validator: (value) =>
                    value?.trim().isEmpty ?? true ? "Required" : null,
                onSaved: (value) => description = value?.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Amount (₹)"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Enter amount";
                  }
                  if (double.tryParse(value) == null) {
                    return "Invalid number";
                  }
                  return null;
                },
                onSaved: (value) => amount = double.parse(value!.trim()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: "Expense Type"),
                items: expenseTypes
                    .map((et) =>
                        DropdownMenuItem(value: et, child: Text(et)))
                    .toList(),
                onChanged: (val) => type = val ?? type,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Select type' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text("Add Expense"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    final expenseData = {
                      'description': description!,
                      'amount': amount!,
                      'type': type,
                      'date': Timestamp.now(),
                      'addedBy': "temp_user_id",
                      'addedAt': Timestamp.now(),
                    };

                    try {
                      await ref
                          .read(markExpenseFutureProvider(expenseData).future);
                      await addNotification(
                        title: 'New Expense',
                        body:
                            '$description ₹${amount!.toStringAsFixed(2)} ($type)',
                      );
                      if (context.mounted) Navigator.of(context).pop();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Failed to add expense: $e")),
                        );
                      }
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Show Edit Expense Bottom Sheet
void showEditExpenseDialog(
  BuildContext context,
  ExpenseModel expense,
  WidgetRef ref,
) async {
  final formKey = GlobalKey<FormState>();
  String updatedDescription = expense.description;
  double updatedAmount = expense.amount;

  final expenseTypes = await _loadExpenseTypes();
  String updatedType = expense.type ?? expenseTypes.first;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Edit Expense",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: updatedDescription,
                decoration: const InputDecoration(labelText: "Description"),
                validator: (value) =>
                    value?.trim().isEmpty ?? true ? "Required" : null,
                onSaved: (value) =>
                    updatedDescription = value?.trim() ?? updatedDescription,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: updatedAmount.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Amount (₹)"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Enter amount";
                  }
                  if (double.tryParse(value) == null) {
                    return "Invalid number";
                  }
                  return null;
                },
                onSaved: (value) =>
                    updatedAmount = double.parse(value!.trim()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: updatedType,
                decoration: const InputDecoration(labelText: "Expense Type"),
                items: expenseTypes
                    .map((et) =>
                        DropdownMenuItem(value: et, child: Text(et)))
                    .toList(),
                onChanged: (val) => updatedType = val ?? updatedType,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Select type' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Update Expense"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    final updatedData = {
                      'description': updatedDescription,
                      'amount': updatedAmount,
                      'type': updatedType,
                      'editedBy': "temp_user_id",
                      'editedAt': Timestamp.now(),
                    };

                    try {
                      await ref.read(
                        updateExpenseFutureProvider({
                          'id': expense.id,
                          'data': updatedData,
                        }).future,
                      );
                      await addNotification(
                        title: 'Expense Updated',
                        body:
                            '$updatedDescription ₹${updatedAmount.toStringAsFixed(2)} ($updatedType)',
                      );
                      if (context.mounted) Navigator.of(context).pop();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Failed to update expense: $e"),
                          ),
                        );
                      }
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );
}
