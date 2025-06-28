import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/expense_viewmodel.dart';
import '../../utils/format_utils.dart';
import '../../constants/app_constants.dart';
import '../../utils/capitalize.dart';

class TodayExpenseScreen extends ConsumerStatefulWidget {
  const TodayExpenseScreen({super.key});

  @override
  ConsumerState<TodayExpenseScreen> createState() => _TodayExpenseScreenState();
}

class _TodayExpenseScreenState extends ConsumerState<TodayExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _description;
  double? _amount;
  String _type = AppConstants.expenseRawMaterial;

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(todaysExpensesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Today's Expense")),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (expenses) {
          final total = expenses.fold<double>(
            0.0,
            (total, item) => total + item.amount,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔴 Summary Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Total Expenses",
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              FormatUtils.formatCurrency(total),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "Entries",
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              expenses.length.toString(),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                /// ✍️ Add Expense Inline Form
                Text(
                  "Add New Expense",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: "Description",
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? "Required"
                            : null,
                        onSaved: (val) => _description = val!.trim(),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: "Amount (₹)",
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return "Required";
                          }
                          if (double.tryParse(val) == null) {
                            return "Invalid number";
                          }
                          return null;
                        },
                        onSaved: (val) => _amount = double.parse(val!),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _type,
                        decoration: const InputDecoration(
                          labelText: "Expense Type",
                        ),
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
                        onChanged: (val) => setState(() => _type = val!),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text("Add Expense"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            final currentContext = context;

                            final expenseData = {
                              'description': _description!,
                              'amount': _amount!,
                              'type': _type,
                              'date': Timestamp.now(),
                              'addedBy':
                                  'temp_user_id', // Replace with real user ID
                              'addedAt': Timestamp.now(),
                            };

                            try {
                              await ref.read(
                                markExpenseFutureProvider(expenseData).future,
                              );

                              if (currentContext.mounted) {
                                // ✅ Refresh provider and reset form
                                ref.invalidate(todaysExpensesStreamProvider);
                                _formKey.currentState!.reset();
                                setState(
                                  () => _type = AppConstants.expenseRawMaterial,
                                );

                                ScaffoldMessenger.of(
                                  currentContext,
                                ).showSnackBar(
                                  const SnackBar(
                                    content: Text("Expense added successfully"),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (currentContext.mounted) {
                                ScaffoldMessenger.of(
                                  currentContext,
                                ).showSnackBar(
                                  SnackBar(content: Text("Failed: $e")),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                /// 📃 Expense List
                Text(
                  "Today's Expenses",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                ListView.builder(
                  itemCount: expenses.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(expense.description),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Amount: ₹${expense.amount.toStringAsFixed(2)}",
                            ),
                            Text("Type: ${expense.type.capitalize()}"),
                            Text(
                              "Added at: ${FormatUtils.formatTime(expense.addedAt)}",
                            ),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.receipt_long,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
