import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/expense_viewmodel.dart';
import '../../utils/format_utils.dart';
import '../../utils/capitalize.dart';
import 'expense_dialogs.dart';

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(todaysExpensesStreamProvider);

    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
      data: (expenses) {
        if (expenses.isEmpty) {
          return const Center(child: Text("No expenses recorded today."));
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: expenses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final expense = expenses[index];

            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                title: Text(
                  expense.description,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text("Amount: ₹${FormatUtils.formatCurrency(expense.amount)}"),
                    Text("Type: ${expense.type.capitalize()}"),
                    Text("Added at: ${FormatUtils.formatTime(expense.addedAt)} by ${expense.addedBy}"),
                    if (expense.editedAt != null)
                      Text(
                        "Edited at: ${FormatUtils.formatTime(expense.editedAt!)} by ${expense.editedBy}",
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                  onPressed: () {
                    showEditExpenseDialog(context, expense, ref);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
