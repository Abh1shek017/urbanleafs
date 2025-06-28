import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/expense_provider.dart';
import '../../models/expense_model.dart';
import '../../repositories/expense_repository.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';

class BalanceSheetScreen extends ConsumerWidget {
  BalanceSheetScreen({super.key});

  final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(todaysExpensesStreamProvider);
    final userModelAsync = ref.watch(currentUserStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Balance Sheet')),
      body: userModelAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading user: $e')),
        data: (userModel) {
          if (userModel == null) {
            return const Center(child: Text('User not found.'));
          }

          final isAdmin = userModel.role == UserRole.admin;

          return expensesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (expenses) {
              if (expenses.isEmpty) {
                return const Center(child: Text('No expenses recorded.'));
              }

              return ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final exp = expenses[index];

                  return ListTile(
                    title: Text(exp.description),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('₹${exp.amount.toStringAsFixed(2)}'),
                        Text('Type: ${exp.type}'),
                        Text(
                          'Added: ${dateFormat.format(exp.addedAt)} by ${exp.addedBy}',
                        ),
                        if (exp.editedAt != null && exp.editedBy != null)
                          Text(
                            'Edited: ${dateFormat.format(exp.editedAt!)} by ${exp.editedBy}',
                          ),
                      ],
                    ),
                    trailing: (userModel.id == exp.addedBy || isAdmin)
                        ? IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                _showEditExpenseDialog(context, exp),
                          )
                        : null,
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: userModelAsync.maybeWhen(
        data: (userModel) {
          if (userModel == null) return null;
          return FloatingActionButton(
            onPressed: () => _showAddExpenseDialog(context, userModel.id),
            child: const Icon(Icons.add),
          );
        },
        orElse: () => null,
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, String userId) {
    final formKey = GlobalKey<FormState>();
    String description = '';
    double amount = 0.0;
    String type = 'rawMaterial';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                  onSaved: (value) => description = value!.trim(),
                ),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (double.tryParse(value) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                  onSaved: (value) => amount = double.parse(value!),
                ),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'rawMaterial',
                      child: Text('Raw Material'),
                    ),
                    DropdownMenuItem(
                      value: 'transportation',
                      child: Text('Transportation'),
                    ),
                    DropdownMenuItem(value: 'labor', child: Text('Labor')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (val) {
                    if (val != null) type = val;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      final currentContext = context;
                      final repo = ExpenseRepository();
                      await repo.addExpense({
                        'description': description,
                        'amount': amount,
                        'type': type,
                        'date': Timestamp.now(),
                        'addedBy': userId,
                        'addedAt': Timestamp.now(),
                      });
                      if (currentContext.mounted) {
                        Navigator.of(currentContext).pop();
                      }
                    }
                  },
                  child: const Text('Add Expense'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditExpenseDialog(BuildContext context, ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Expense'),
        content: const Text('Edit dialog not implemented.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
