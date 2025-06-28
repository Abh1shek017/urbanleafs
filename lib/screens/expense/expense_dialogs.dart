import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_constants.dart';
import '../../models/expense_model.dart';
import '../../viewmodels/expense_viewmodel.dart';

/// Show Add Expense Dialog (Bottom Sheet)
void showAddExpenseDialog(BuildContext context, WidgetRef ref) {
  final formKey = GlobalKey<FormState>();
  String? description;
  double? amount;
  String type = AppConstants.expenseRawMaterial;

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
                    value?.isEmpty ?? true ? "Required" : null,
                onSaved: (value) => description = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Amount (₹)"),
                validator: (value) {
                  if ((value?.isEmpty ?? true) ||
                      double.tryParse(value!) == null) {
                    return "Enter valid amount";
                  }
                  return null;
                },
                onSaved: (value) => amount = double.parse(value!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: "Expense Type"),
                items: [
                  DropdownMenuItem(
                    value: AppConstants.expenseRawMaterial,
                    child: Text("Raw Material"),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.expenseTransportation,
                    child: Text("Transportation"),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.expenseLabor,
                    child: Text("Labor"),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.expenseOther,
                    child: Text("Other"),
                  ),
                ],
                onChanged: (val) => type = val!,
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
                    final currentContext = context;
                    final userId =
                        "temp_user_id"; // Replace with actual user ID
                    final expenseData = {
                      'description': description!,
                      'amount': amount!,
                      'type': type,
                      'date': Timestamp.now(),
                      'addedBy': userId,
                      'addedAt': Timestamp.now(),
                    };

                    try {
                      await ref.read(
                        markExpenseFutureProvider(expenseData).future,
                      );
                      if (currentContext.mounted) {
                        Navigator.of(currentContext).pop();
                      }
                    } catch (e) {
                      if (currentContext.mounted) {
                        ScaffoldMessenger.of(currentContext).showSnackBar(
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

/// Show Edit Expense Dialog (Bottom Sheet)
void showEditExpenseDialog(
  BuildContext context,
  ExpenseModel expense,
  WidgetRef ref,
) {
  final formKey = GlobalKey<FormState>();
  String updatedDescription = expense.description;
  double updatedAmount = expense.amount;
  String updatedType = expense.type;

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
                    value?.isEmpty ?? true ? "Required" : null,
                onSaved: (value) =>
                    updatedDescription = value ?? updatedDescription,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: updatedAmount.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Amount (₹)"),
                validator: (value) {
                  if ((value?.isEmpty ?? true) ||
                      double.tryParse(value!) == null) {
                    return "Enter valid amount";
                  }
                  return null;
                },
                onSaved: (value) => updatedAmount = double.parse(value!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: updatedType,
                decoration: const InputDecoration(labelText: "Expense Type"),
                items: [
                  DropdownMenuItem(
                    value: AppConstants.expenseRawMaterial,
                    child: Text("Raw Material"),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.expenseTransportation,
                    child: Text("Transportation"),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.expenseLabor,
                    child: Text("Labor"),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.expenseOther,
                    child: Text("Other"),
                  ),
                ],
                onChanged: (val) => updatedType = val!,
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
                    final currentContext = context;
                    final userId =
                        "temp_user_id"; // Replace with actual user ID
                    final updatedData = {
                      'description': updatedDescription,
                      'amount': updatedAmount,
                      'type': updatedType,
                      'editedBy': userId,
                      'editedAt': Timestamp.now(),
                    };

                    try {
                      await ref.read(
                        updateExpenseFutureProvider({
                          'id': expense.id,
                          'data': updatedData,
                        }).future,
                      );
                      if (currentContext.mounted) {
                        Navigator.of(currentContext).pop();
                      }
                    } catch (e) {
                      if (currentContext.mounted) {
                        ScaffoldMessenger.of(currentContext).showSnackBar(
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
